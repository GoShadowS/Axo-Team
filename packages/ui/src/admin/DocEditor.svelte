<script lang="ts">
  import { untrack } from 'svelte';
  import Markdown from '../components/Markdown.svelte';
  import { createDoc, deleteDoc, updateDoc } from '../lib/api';
  import { describeError } from '../lib/errors';
  import { checkSlug, checkText, firstError, LIMITS } from '../lib/validate';
  import type { ProjectDoc } from '../types';

  interface Props {
    projectId: string;
    /** null — форма нового документа. */
    doc: ProjectDoc | null;
    onchange: () => void | Promise<void>;
  }

  let { projectId, doc, onchange }: Props = $props();

  // Форма заполняется один раз, при создании; дальше в ней живёт ввод пользователя.
  const initial = untrack(() => doc);

  let title = $state(initial?.title ?? '');
  let slug = $state(initial?.slug ?? '');
  let sortOrder = $state(initial?.sort_order ?? 100);
  let body = $state(initial?.body_md ?? '');
  let preview = $state(false);
  let busy = $state(false);
  let error = $state<string | null>(null);
  let saved = $state(false);

  async function save(event: SubmitEvent) {
    event.preventDefault();
    saved = false;
    error = firstError(
      checkText(title, LIMITS.docTitle.min, LIMITS.docTitle.max, 'Заголовок документа'),
      checkSlug(slug.trim()),
      body.length > LIMITS.docBody.max ? `Текст: не длиннее ${LIMITS.docBody.max} символов.` : null,
    );
    if (error) return;

    busy = true;
    try {
      const input = { title: title.trim(), slug: slug.trim(), body_md: body, sort_order: Number(sortOrder) || 0 };
      if (doc) {
        await updateDoc(doc.id, input);
        saved = true;
      } else {
        await createDoc(projectId, input);
        title = '';
        slug = '';
        body = '';
      }
      await onchange();
    } catch (caught) {
      error = describeError(caught);
    } finally {
      busy = false;
    }
  }

  async function remove() {
    if (!doc || !confirm(`Удалить документ «${doc.title}»? Вернуть его будет нельзя.`)) return;
    busy = true;
    try {
      await deleteDoc(doc.id);
      await onchange();
    } catch (caught) {
      error = describeError(caught);
      busy = false;
    }
  }
</script>

<form class="form form--wide" onsubmit={save} novalidate>
  <div class="field-row">
    <label class="field">
      <span>Заголовок</span>
      <input type="text" bind:value={title} maxlength={LIMITS.docTitle.max} placeholder="Установка" disabled={busy} />
    </label>
    <label class="field">
      <span>Адрес (slug)</span>
      <input type="text" bind:value={slug} maxlength={LIMITS.slug.max} placeholder="install" disabled={busy} />
    </label>
    <label class="field">
      <span>Порядок</span>
      <input type="number" bind:value={sortOrder} step="10" disabled={busy} />
    </label>
  </div>

  <div class="field">
    <div class="body-head">
      <label for="doc-body-{doc?.id ?? 'new'}">Текст в Markdown</label>
      <button class="link-button small" type="button" onclick={() => (preview = !preview)}>
        {preview ? 'Вернуться к тексту' : 'Предпросмотр'}
      </button>
    </div>
    {#if preview}
      <div class="panel preview"><Markdown source={body} /></div>
    {:else}
      <textarea id="doc-body-{doc?.id ?? 'new'}" class="body" bind:value={body} disabled={busy} spellcheck="true"></textarea>
    {/if}
    <small>{body.length} / {LIMITS.docBody.max}</small>
  </div>

  {#if error}<p class="notice notice--error" role="alert">{error}</p>{/if}
  {#if saved}<p class="notice notice--ok" role="status">Документ сохранён.</p>{/if}

  <div class="actions">
    <button class="button button--ghost button--small" type="submit" disabled={busy}>
      {doc ? 'Сохранить документ' : 'Добавить документ'}
    </button>
    {#if doc}
      <button class="link-button small" type="button" onclick={remove} disabled={busy}>Удалить документ</button>
    {/if}
  </div>
</form>

<style>
  .body-head {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 1rem;
  }

  .body-head label {
    font-size: 0.875rem;
    font-weight: 600;
  }

  .body {
    min-height: 16rem;
    font-family: var(--axo-font-mono);
    font-size: 0.875rem;
  }

  .preview {
    min-height: 16rem;
    background: var(--axo-bg);
  }
</style>
