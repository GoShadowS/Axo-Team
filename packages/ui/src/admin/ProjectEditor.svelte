<script lang="ts">
  import { untrack } from 'svelte';
  import { createProject, deleteProject, updateProject } from '../lib/api';
  import { describeError } from '../lib/errors';
  import { href } from '../lib/routes';
  import { checkSlug, checkText, firstError, LIMITS } from '../lib/validate';
  import type { ProjectDetails, ProjectStatus } from '../types';
  import DocEditor from './DocEditor.svelte';
  import LinkEditor from './LinkEditor.svelte';

  interface Props {
    /** null — новый проект. */
    project: ProjectDetails | null;
    /** Проект сохранён; slug — его актуальный адрес. */
    onsaved: (slug: string) => void | Promise<void>;
    ondeleted: () => void | Promise<void>;
    /** Документы или ссылки изменились. */
    onchange: () => void | Promise<void>;
  }

  let { project, onsaved, ondeleted, onchange }: Props = $props();

  // Форма заполняется один раз, при создании; дальше в ней живёт ввод пользователя.
  const initial = untrack(() => project);

  let title = $state(initial?.title ?? '');
  let slug = $state(initial?.slug ?? '');
  let kind = $state(initial?.kind ?? '');
  let summary = $state(initial?.summary ?? '');
  let status = $state<ProjectStatus>(initial?.status ?? 'active');
  let stack = $state(initial?.stack.join(', ') ?? '');
  let license = $state(initial?.license ?? '');
  let sortOrder = $state(initial?.sort_order ?? 100);
  let isPublished = $state(initial?.is_published ?? false);

  let busy = $state(false);
  let error = $state<string | null>(null);
  let saved = $state(false);

  async function save(event: SubmitEvent) {
    event.preventDefault();
    saved = false;
    error = firstError(
      checkText(title, LIMITS.projectTitle.min, LIMITS.projectTitle.max, 'Название'),
      checkSlug(slug.trim()),
      checkText(kind, 0, LIMITS.projectKind.max, 'Тип'),
      checkText(summary, 0, LIMITS.projectSummary.max, 'Краткое описание'),
      checkText(license, 0, LIMITS.license.max, 'Лицензия'),
    );
    if (error) return;

    busy = true;
    try {
      const input = {
        title: title.trim(),
        slug: slug.trim(),
        kind: kind.trim(),
        summary: summary.trim(),
        status,
        stack: stack
          .split(',')
          .map((item) => item.trim())
          .filter((item) => item !== ''),
        license: license.trim() === '' ? null : license.trim(),
        sort_order: Number(sortOrder) || 0,
        is_published: isPublished,
      };
      const result = project ? await updateProject(project.id, input) : await createProject(input);
      saved = true;
      await onsaved(result.slug);
    } catch (caught) {
      error = describeError(caught);
    } finally {
      busy = false;
    }
  }

  async function remove() {
    if (!project) return;
    const sure = confirm(
      `Удалить проект «${project.title}» вместе с документами, ссылками и комментариями? Вернуть его будет нельзя.`,
    );
    if (!sure) return;

    busy = true;
    try {
      await deleteProject(project.id);
      await ondeleted();
    } catch (caught) {
      error = describeError(caught);
      busy = false;
    }
  }
</script>

<form class="form form--wide" onsubmit={save} novalidate>
  <div class="field-row">
    <label class="field">
      <span>Название</span>
      <input type="text" bind:value={title} maxlength={LIMITS.projectTitle.max} disabled={busy} />
    </label>
    <label class="field">
      <span>Адрес (slug)</span>
      <input type="text" bind:value={slug} maxlength={LIMITS.slug.max} placeholder="my-project" disabled={busy} />
    </label>
  </div>
  <div class="field-row">
    <label class="field">
      <span>Тип</span>
      <input type="text" bind:value={kind} maxlength={LIMITS.projectKind.max} placeholder="Мод для Minecraft" disabled={busy} />
    </label>
    <label class="field">
      <span>Состояние</span>
      <select bind:value={status} disabled={busy}>
        <option value="active">В разработке</option>
        <option value="experimental">Эксперимент</option>
      </select>
    </label>
  </div>
  <label class="field">
    <span>Краткое описание</span>
    <textarea class="summary" bind:value={summary} maxlength={LIMITS.projectSummary.max} disabled={busy}></textarea>
    <small>Показывается на карточке. {summary.trim().length} / {LIMITS.projectSummary.max}</small>
  </label>
  <div class="field-row">
    <label class="field">
      <span>Технологии</span>
      <input type="text" bind:value={stack} placeholder="Java, Kotlin, Fabric" disabled={busy} />
      <small>Через запятую.</small>
    </label>
    <label class="field">
      <span>Лицензия</span>
      <input type="text" bind:value={license} maxlength={LIMITS.license.max} placeholder="MIT" disabled={busy} />
    </label>
    <label class="field">
      <span>Порядок в каталоге</span>
      <input type="number" bind:value={sortOrder} step="10" disabled={busy} />
      <small>Меньше — выше.</small>
    </label>
  </div>
  <label class="check">
    <input type="checkbox" bind:checked={isPublished} disabled={busy} />
    <span>Показывать в каталоге всем</span>
  </label>

  {#if error}<p class="notice notice--error" role="alert">{error}</p>{/if}
  {#if saved}<p class="notice notice--ok" role="status">Проект сохранён.</p>{/if}

  <div class="actions">
    <button class="button" type="submit" disabled={busy}>
      {busy ? 'Сохраняю…' : project ? 'Сохранить проект' : 'Создать проект'}
    </button>
    {#if project}
      <a class="button button--ghost" href={href({ name: 'project', slug: project.slug })}>Открыть страницу</a>
      <button class="button button--danger" type="button" onclick={remove} disabled={busy}>Удалить проект</button>
    {/if}
  </div>
</form>

{#if project}
  <h3>Ссылки</h3>
  <div class="items">
    {#each project.links as link (link.id)}
      <LinkEditor projectId={project.id} {link} {onchange} />
    {/each}
    <LinkEditor projectId={project.id} link={null} {onchange} />
  </div>

  <h3>Документация</h3>
  <div class="items">
    {#each project.docs as doc (doc.id)}
      <details class="panel">
        <summary>{doc.title} <span class="muted small">/{doc.slug} · порядок {doc.sort_order}</span></summary>
        <DocEditor projectId={project.id} {doc} {onchange} />
      </details>
    {/each}
    <details class="panel">
      <summary>+ Новый документ</summary>
      <DocEditor projectId={project.id} doc={null} {onchange} />
    </details>
  </div>
{:else}
  <p class="muted small note">Ссылки и документация добавляются после того, как проект создан.</p>
{/if}

<style>
  .summary {
    min-height: 5rem;
  }

  h3 {
    margin: 2.25rem 0 0.875rem;
    font-size: 1.125rem;
  }

  .items {
    display: grid;
    gap: 1rem;
    max-width: 46rem;
  }

  summary {
    cursor: pointer;
    font-weight: 600;
  }

  details[open] > summary {
    margin-bottom: 1rem;
  }

  .note {
    margin: 1.25rem 0 0;
  }
</style>
