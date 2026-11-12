<script lang="ts">
  import { onMount } from 'svelte';
  import { addComment, deleteComment, listComments, setCommentHidden } from '../lib/api';
  import { describeError } from '../lib/errors';
  import { formatDateTime } from '../lib/format';
  import { LOADING, type Load } from '../lib/load';
  import { currentHref, href } from '../lib/routes';
  import { isAdmin, session } from '../lib/session';
  import { checkComment, LIMITS } from '../lib/validate';
  import type { Comment } from '../types';

  interface Props {
    projectId: string;
  }

  let { projectId }: Props = $props();

  let comments = $state<Load<Comment[]>>(LOADING);
  let body = $state('');
  let sending = $state(false);
  let formError = $state<string | null>(null);
  let actionError = $state<string | null>(null);
  let busyId = $state<string | null>(null);
  let next = $state<string | undefined>(undefined);

  // Список зависит от того, кто смотрит: автор и владелец видят скрытые комментарии.
  // Поэтому после входа или выхода он загружается заново.
  let loadedFor: string | null | undefined;

  async function load() {
    try {
      comments = { state: 'ready', data: await listComments(projectId) };
    } catch (error) {
      comments = { state: 'error', message: describeError(error) };
    }
  }

  $effect(() => {
    if (!$session.ready) return;
    const viewer = $session.user?.id ?? null;
    if (viewer === loadedFor) return;
    loadedFor = viewer;
    void load();
  });

  onMount(() => {
    next = currentHref();
  });

  async function submit(event: SubmitEvent) {
    event.preventDefault();
    formError = checkComment(body);
    if (formError) return;

    sending = true;
    try {
      const created = await addComment(projectId, body.trim());
      if (comments.state === 'ready') comments = { state: 'ready', data: [created, ...comments.data] };
      else await load();
      body = '';
    } catch (error) {
      formError = describeError(error);
    } finally {
      sending = false;
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
</script>

<section class="comments" aria-labelledby="comments-title">
  <h2 id="comments-title">
    Комментарии
    {#if comments.state === 'ready'}<span class="muted count">{comments.data.length}</span>{/if}
  </h2>

  {#if $session.user}
    <form class="form form--wide" onsubmit={submit} novalidate>
      <label class="field">
        <span>Ваш комментарий</span>
        <textarea
          bind:value={body}
          maxlength={LIMITS.comment.max}
          placeholder="Отзыв, вопрос или идея"
          required
          disabled={sending}></textarea>
        <small>{body.trim().length} / {LIMITS.comment.max}</small>
      </label>
      {#if formError}<p class="notice notice--error" role="alert">{formError}</p>{/if}
      <div class="actions">
        <button class="button" type="submit" disabled={sending}>
          {sending ? 'Отправляю…' : 'Отправить'}
        </button>
        <span class="muted small">
          от имени «{$session.profile?.display_name ?? $session.user.email}»
        </span>
      </div>
    </form>
  {:else if $session.ready}
    <p class="notice notice--info">
      Чтобы оставить комментарий,
      <a href={href({ name: 'login', next })}>войдите</a> или
      <a href={href({ name: 'register', next })}>создайте аккаунт</a>.
    </p>
  {/if}

  {#if actionError}<p class="notice notice--error" role="alert">{actionError}</p>{/if}

  {#if comments.state === 'loading'}
    <p class="muted" role="status">Загружаю комментарии…</p>
  {:else if comments.state === 'error'}
    <p class="notice notice--error" role="alert">{comments.message}</p>
  {:else if comments.data.length === 0}
    <p class="muted">Комментариев пока нет. Ваш будет первым.</p>
  {:else}
    <ul class="stack-list">
      {#each comments.data as comment (comment.id)}
        {@const own = comment.author_id === $session.user?.id}
        <li class="panel comment" class:comment--hidden={comment.is_hidden}>
          <header>
            <strong>{comment.author?.display_name ?? 'Аккаунт удалён'}</strong>
            {#if comment.author?.role === 'admin'}<span class="badge badge--teal">Автор проектов</span>{/if}
            {#if comment.is_hidden}<span class="badge badge--warn">Скрыт</span>{/if}
            <time class="muted small" datetime={comment.created_at}>{formatDateTime(comment.created_at)}</time>
          </header>
          <p class="body">{comment.body}</p>
          {#if own || $isAdmin}
            <div class="actions">
              {#if $isAdmin}
                <button
                  class="link-button small"
                  type="button"
                  disabled={busyId === comment.id}
                  onclick={() => run(comment.id, () => setCommentHidden(comment.id, !comment.is_hidden))}>
                  {comment.is_hidden ? 'Показать' : 'Скрыть'}
                </button>
              {/if}
              <button
                class="link-button small"
                type="button"
                disabled={busyId === comment.id}
                onclick={() => remove(comment)}>
                Удалить
              </button>
            </div>
          {/if}
        </li>
      {/each}
    </ul>
  {/if}
</section>

<style>
  .comments {
    display: grid;
    gap: 1.25rem;
    max-width: 46rem;
  }

  h2 {
    margin: 0;
    font-size: 1.375rem;
  }

  .count {
    margin-left: 0.375rem;
    font-size: 1rem;
    font-weight: 400;
  }

  .comment header {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.375rem 0.625rem;
  }

  .comment time {
    margin-left: auto;
  }

  .comment--hidden {
    border-style: dashed;
  }

  .body {
    margin: 0.625rem 0 0;
    overflow-wrap: anywhere;
    white-space: pre-wrap;
  }

  .comment .actions {
    margin-top: 0.75rem;
  }
</style>
