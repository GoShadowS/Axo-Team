<script lang="ts">
  import { deleteBug, setBugHidden, setBugStatus } from '../lib/api';
  import { describeError } from '../lib/errors';
  import { formatDateTime } from '../lib/format';
  import { href } from '../lib/routes';
  import { isAdmin, session } from '../lib/session';
  import { BUG_STATUS_LABEL, BUG_STATUSES, type Bug, type BugStatus } from '../types';

  interface Props {
    bugs: Bug[];
    /** Вызывается после правки, чтобы список перечитали. */
    onchange: () => void | Promise<void>;
  }

  let { bugs, onchange }: Props = $props();

  let busyId = $state<string | null>(null);
  let actionError = $state<string | null>(null);

  const BADGE: Record<BugStatus, string> = {
    new: 'badge--warn',
    confirmed: 'badge--teal',
    in_progress: 'badge--teal',
    fixed: 'badge--ok',
    rejected: '',
  };

  async function run(id: string, action: () => Promise<void>) {
    busyId = id;
    actionError = null;
    try {
      await action();
      await onchange();
    } catch (error) {
      actionError = describeError(error);
    } finally {
      busyId = null;
    }
  }

  function changeStatus(bug: Bug, event: Event) {
    const status = (event.currentTarget as HTMLSelectElement).value as BugStatus;
    if (status !== bug.status) void run(bug.id, () => setBugStatus(bug.id, status));
  }

  function remove(bug: Bug) {
    if (!confirm(`Удалить репорт №${bug.number}? Вернуть его будет нельзя.`)) return;
    void run(bug.id, () => deleteBug(bug.id));
  }
</script>

{#if actionError}<p class="notice notice--error" role="alert">{actionError}</p>{/if}

<ul class="stack-list">
  {#each bugs as bug (bug.id)}
    {@const own = bug.author_id === $session.user?.id}
    <li class="panel bug" class:bug--hidden={bug.is_hidden}>
      <header>
        <span class="muted">№{bug.number}</span>
        <h3>{bug.title}</h3>
        <span class="badge {BADGE[bug.status]}">{BUG_STATUS_LABEL[bug.status]}</span>
        {#if bug.is_hidden}<span class="badge badge--warn">Скрыт</span>{/if}
      </header>
      <p class="meta muted small">
        {#if bug.project}
          <a href={href({ name: 'project', slug: bug.project.slug })}>{bug.project.title}</a>
        {:else}
          Сайт или приложение
        {/if}
        · {bug.author?.display_name ?? 'Аккаунт удалён'}
        · <time datetime={bug.created_at}>{formatDateTime(bug.created_at)}</time>
      </p>
      <p class="body">{bug.body}</p>

      {#if $isAdmin || (own && bug.status === 'new')}
        <div class="actions">
          {#if $isAdmin}
            <label class="status-select">
              <span class="small muted">Статус</span>
              <select value={bug.status} disabled={busyId === bug.id} onchange={(event) => changeStatus(bug, event)}>
                {#each BUG_STATUSES as status (status)}
                  <option value={status}>{BUG_STATUS_LABEL[status]}</option>
                {/each}
              </select>
            </label>
            <button
              class="link-button small"
              type="button"
              disabled={busyId === bug.id}
              onclick={() => run(bug.id, () => setBugHidden(bug.id, !bug.is_hidden))}>
              {bug.is_hidden ? 'Показать' : 'Скрыть'}
            </button>
          {/if}
          <button class="link-button small" type="button" disabled={busyId === bug.id} onclick={() => remove(bug)}>
            {$isAdmin ? 'Удалить' : 'Отозвать репорт'}
          </button>
        </div>
      {/if}
    </li>
  {/each}
</ul>

<style>
  .bug header {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: 0.375rem 0.625rem;
  }

  h3 {
    margin: 0;
    font-size: 1.0625rem;
    overflow-wrap: anywhere;
  }

  .meta {
    margin: 0.25rem 0 0;
  }

  .body {
    margin: 0.75rem 0 0;
    overflow-wrap: anywhere;
    white-space: pre-wrap;
  }

  .bug--hidden {
    border-style: dashed;
  }

  .bug .actions {
    margin-top: 0.875rem;
  }

  .status-select {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
  }

  .status-select select {
    width: auto;
    padding: 0.25rem 0.5rem;
    font-size: 0.875rem;
  }
</style>
