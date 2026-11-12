<script lang="ts">
  import { onMount } from 'svelte';
  import { deleteComment, listRecentComments, setCommentHidden } from '../lib/api';
  import { describeError } from '../lib/errors';
  import { formatDateTime } from '../lib/format';
  import { LOADING, type Load } from '../lib/load';
  import { href } from '../lib/routes';
  import type { Comment } from '../types';

  let comments = $state<Load<Comment[]>>(LOADING);
  let busyId = $state<string | null>(null);
  let actionError = $state<string | null>(null);

  async function load() {
    try {
      comments = { state: 'ready', data: await listRecentComments() };
    } catch (error) {
      comments = { state: 'error', message: describeError(error) };
    }
  }

  async function run(id: string, action: () => Promise<void>) {
    busyId = id;
    actionError = null;
    try {
      await action();
      await load();
    } catch (error) {
      actionError = describeError(error);
    } finally {
      busyId = null;
    }
  }

  function remove(comment: Comment) {
    if (!confirm('Удалить комментарий? Вернуть его будет нельзя.')) return;
    void run(comment.id, () => deleteComment(comment.id));
  }

  onMount(load);
</script>

{#if actionError}<p class="notice notice--error" role="alert">{actionError}</p>{/if}

{#if comments.state === 'loading'}
  <p class="muted" role="status">Загружаю комментарии…</p>
{:else if comments.state === 'error'}
  <p class="notice notice--error" role="alert">{comments.message}</p>
{:else if comments.data.length === 0}
  <p class="muted">Комментариев пока нет.</p>
{:else}
  <p class="muted small">Последние {comments.data.length} по всем проектам, включая скрытые.</p>
  <ul class="stack-list">
    {#each comments.data as comment (comment.id)}
      <li class="panel" class:hidden={comment.is_hidden}>
        <p class="meta muted small">
          <strong>{comment.author?.display_name ?? 'Аккаунт удалён'}</strong>
          {#if comment.project}
            · <a href={href({ name: 'project', slug: comment.project.slug })}>{comment.project.title}</a>
          {/if}
          · <time datetime={comment.created_at}>{formatDateTime(comment.created_at)}</time>
          {#if comment.is_hidden}<span class="badge badge--warn">Скрыт</span>{/if}
        </p>
        <p class="body">{comment.body}</p>
        <div class="actions">
          <button
            class="link-button small"
            type="button"
            disabled={busyId === comment.id}
            onclick={() => run(comment.id, () => setCommentHidden(comment.id, !comment.is_hidden))}>
            {comment.is_hidden ? 'Показать' : 'Скрыть'}
          </button>
          <button class="link-button small" type="button" disabled={busyId === comment.id} onclick={() => remove(comment)}>
            Удалить
          </button>
        </div>
      </li>
    {/each}
  </ul>
{/if}

<style>
  .meta {
    margin: 0;
  }

  .meta strong {
    color: var(--axo-text);
  }

  .body {
    margin: 0.5rem 0 0.75rem;
    overflow-wrap: anywhere;
    white-space: pre-wrap;
  }

  .hidden {
    border-style: dashed;
  }
</style>
