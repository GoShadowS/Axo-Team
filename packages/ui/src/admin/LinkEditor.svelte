<script lang="ts">
  import { untrack } from 'svelte';
  import { createLink, deleteLink, updateLink } from '../lib/api';
  import { describeError } from '../lib/errors';
  import { checkText, checkUrl, firstError, LIMITS } from '../lib/validate';
  import type { ProjectLink } from '../types';

  interface Props {
    projectId: string;
    /** null — форма новой ссылки. */
    link: ProjectLink | null;
    onchange: () => void | Promise<void>;
  }

  let { projectId, link, onchange }: Props = $props();

  // Форма заполняется один раз, при создании; дальше в ней живёт ввод пользователя.
  const initial = untrack(() => link);

  let label = $state(initial?.label ?? '');
  let url = $state(initial?.url ?? '');
  let sortOrder = $state(initial?.sort_order ?? 100);
  let busy = $state(false);
  let error = $state<string | null>(null);

  async function save(event: SubmitEvent) {
    event.preventDefault();
    error = firstError(
      checkText(label, LIMITS.linkLabel.min, LIMITS.linkLabel.max, 'Название ссылки'),
      checkUrl(url),
    );
    if (error) return;

    busy = true;
    try {
      const input = { label: label.trim(), url: url.trim(), sort_order: Number(sortOrder) || 0 };
      if (link) {
        await updateLink(link.id, input);
      } else {
        await createLink(projectId, input);
        label = '';
        url = '';
      }
      await onchange();
    } catch (caught) {
      error = describeError(caught);
    } finally {
      busy = false;
    }
  }

  async function remove() {
    if (!link || !confirm(`Удалить ссылку «${link.label}»?`)) return;
    busy = true;
    try {
      await deleteLink(link.id);
      await onchange();
    } catch (caught) {
      error = describeError(caught);
      busy = false;
    }
  }
</script>

<form class="link" onsubmit={save} novalidate>
  <label class="field">
    <span>Название</span>
    <input type="text" bind:value={label} maxlength={LIMITS.linkLabel.max} placeholder="Код на GitHub" disabled={busy} />
  </label>
  <label class="field url">
    <span>Адрес</span>
    <input type="url" bind:value={url} maxlength={LIMITS.url.max} placeholder="https://…" disabled={busy} />
  </label>
  <label class="field order">
    <span>Порядок</span>
    <input type="number" bind:value={sortOrder} step="10" disabled={busy} />
  </label>
  <div class="actions">
    <button class="button button--ghost button--small" type="submit" disabled={busy}>
      {link ? 'Сохранить' : 'Добавить ссылку'}
    </button>
    {#if link}
      <button class="link-button small" type="button" onclick={remove} disabled={busy}>Удалить</button>
    {/if}
  </div>
  {#if error}<p class="notice notice--error" role="alert">{error}</p>{/if}
</form>

<style>
  .link {
    display: grid;
    grid-template-columns: minmax(0, 12rem) minmax(0, 1fr) 6rem auto;
    gap: 0.75rem;
    align-items: end;
  }

  .notice {
    grid-column: 1 / -1;
  }

  @media (max-width: 48rem) {
    .link {
      grid-template-columns: minmax(0, 1fr);
    }
  }
</style>
