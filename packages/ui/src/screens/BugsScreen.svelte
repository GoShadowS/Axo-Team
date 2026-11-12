<script lang="ts">
  import { onMount } from 'svelte';
  import BugList from '../components/BugList.svelte';
  import { addBug, listBugs, listProjects } from '../lib/api';
  import { isConfigured } from '../lib/config';
  import { describeError } from '../lib/errors';
  import { LOADING, type Load } from '../lib/load';
  import { currentHref, href, queryParam } from '../lib/routes';
  import { session } from '../lib/session';
  import { checkBugBody, checkBugTitle, firstError, LIMITS } from '../lib/validate';
  import { BUG_STATUS_LABEL, BUG_STATUSES, type Bug, type BugStatus, type ProjectSummary } from '../types';

  interface Props {
    /** Адрес проекта, который нужно выбрать в форме. На сайте берётся из ?project=… */
    project?: string;
    /** Без заголовка и формы: только список (вкладка админки). */
    embedded?: boolean;
  }

  let { project, embedded = false }: Props = $props();

  let bugs = $state<Load<Bug[]>>(LOADING);
  let projects = $state<ProjectSummary[]>([]);
  let filter = $state<BugStatus | 'all'>('all');

  let projectId = $state('');
  let title = $state('');
  let body = $state('');
  let sending = $state(false);
  let formError = $state<string | null>(null);
  let sent = $state<number | null>(null);
  let next = $state<string | undefined>(undefined);

  let loadedFor: string | null | undefined;

  const shown = $derived(
    bugs.state === 'ready' ? bugs.data.filter((bug) => filter === 'all' || bug.status === filter) : [],
  );

  const countOf = (status: BugStatus | 'all') =>
    bugs.state !== 'ready'
      ? 0
      : status === 'all'
        ? bugs.data.length
        : bugs.data.filter((bug) => bug.status === status).length;

  async function load() {
    try {
      bugs = { state: 'ready', data: await listBugs() };
    } catch (error) {
      bugs = { state: 'error', message: describeError(error) };
    }
  }

  onMount(() => {
    next = currentHref();
    if (!isConfigured) {
      bugs = { state: 'error', message: describeError(new Error('supabase_not_configured')) };
      return;
    }
    if (embedded) return;

    const wanted = project ?? queryParam('project');
    listProjects()
      .then((list) => {
        projects = list;
        projectId = list.find((item) => item.slug === wanted)?.id ?? '';
      })
      .catch(() => {
        // Без списка проектов форма всё равно работает: репорт уйдёт без привязки к проекту.
      });
  });

  // Автор и владелец видят скрытые репорты, поэтому после входа список перечитывается.
  $effect(() => {
    if (!isConfigured || !$session.ready) return;
    const viewer = $session.user?.id ?? null;
    if (viewer === loadedFor) return;
    loadedFor = viewer;
    void load();
  });

  async function submit(event: SubmitEvent) {
    event.preventDefault();
    sent = null;
    formError = firstError(checkBugTitle(title), checkBugBody(body));
    if (formError) return;

    sending = true;
    try {
      const created = await addBug({ projectId: projectId || null, title: title.trim(), body: body.trim() });
      sent = created.number;
      title = '';
      body = '';
      await load();
    } catch (error) {
      formError = describeError(error);
    } finally {
      sending = false;
    }
  }
</script>

{#snippet list()}
  <ul class="tabs" aria-label="Фильтр по статусу">
    <li>
      <button class="tab" type="button" aria-pressed={filter === 'all'} onclick={() => (filter = 'all')}>
        Все <span class="muted">{countOf('all')}</span>
      </button>
    </li>
    {#each BUG_STATUSES as status (status)}
      <li>
        <button class="tab" type="button" aria-pressed={filter === status} onclick={() => (filter = status)}>
          {BUG_STATUS_LABEL[status]} <span class="muted">{countOf(status)}</span>
        </button>
      </li>
    {/each}
  </ul>

  {#if bugs.state === 'loading'}
    <p class="muted" role="status">Загружаю репорты…</p>
  {:else if bugs.state === 'error'}
    <p class="notice notice--error" role="alert">{bugs.message}</p>
  {:else if shown.length === 0}
    <p class="muted">
      {bugs.data.length === 0 ? 'Репортов пока нет.' : 'С таким статусом репортов нет.'}
    </p>
  {:else}
    <BugList bugs={shown} onchange={load} />
  {/if}
{/snippet}

{#if embedded}
  {@render list()}
{:else}
  <section class="section">
    <div class="container">
      <h1 class="page-title">Баг-репорты</h1>
      <p class="lead">
        Нашли ошибку в проекте, на сайте или в приложении? Опишите её — у репорта появится номер и статус.
      </p>

      <div class="layout">
        <div class="report">
          <h2>Сообщить об ошибке</h2>
          {#if $session.user}
            <form class="form" onsubmit={submit} novalidate>
              <label class="field">
                <span>Где ошибка</span>
                <select bind:value={projectId} disabled={sending}>
                  <option value="">Сайт или приложение</option>
                  {#each projects as item (item.id)}
                    <option value={item.id}>{item.title}</option>
                  {/each}
                </select>
              </label>
              <label class="field">
                <span>Заголовок</span>
                <input
                  type="text"
                  bind:value={title}
                  maxlength={LIMITS.bugTitle.max}
                  placeholder="Коротко: что сломалось"
                  required
                  disabled={sending} />
              </label>
              <label class="field">
                <span>Описание</span>
                <textarea
                  bind:value={body}
                  maxlength={LIMITS.bugBody.max}
                  placeholder="Что вы делали, что ожидали и что получилось. Версия игры, мода, системы."
                  required
                  disabled={sending}></textarea>
                <small>{body.trim().length} / {LIMITS.bugBody.max}</small>
              </label>
              {#if formError}<p class="notice notice--error" role="alert">{formError}</p>{/if}
              {#if sent !== null}
                <p class="notice notice--ok" role="status">Репорт №{sent} отправлен. Спасибо!</p>
              {/if}
              <div class="actions">
                <button class="button" type="submit" disabled={sending}>
                  {sending ? 'Отправляю…' : 'Отправить репорт'}
                </button>
              </div>
            </form>
          {:else if $session.ready}
            <p class="notice notice--info">
              Чтобы отправить репорт,
              <a href={href({ name: 'login', next })}>войдите</a> или
              <a href={href({ name: 'register', next })}>создайте аккаунт</a>.
            </p>
          {:else}
            <p class="muted" role="status">Проверяю аккаунт…</p>
          {/if}
        </div>

        <div class="found">
          <h2>Все репорты</h2>
          {@render list()}
        </div>
      </div>
    </div>
  </section>
{/if}

<style>
  .lead {
    margin: 0 0 2rem;
  }

  .layout {
    display: grid;
    grid-template-columns: minmax(0, 22rem) minmax(0, 1fr);
    gap: 2.5rem;
    align-items: start;
  }

  h2 {
    margin: 0 0 1rem;
    font-size: 1.25rem;
  }

  @media (max-width: 56rem) {
    .layout {
      grid-template-columns: minmax(0, 1fr);
    }
  }
</style>
