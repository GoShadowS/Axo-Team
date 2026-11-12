<script lang="ts">
  import { untrack } from 'svelte';
  import Comments from '../components/Comments.svelte';
  import Markdown from '../components/Markdown.svelte';
  import { getProject } from '../lib/api';
  import { isConfigured, TARGET } from '../lib/config';
  import { describeError } from '../lib/errors';
  import { LOADING, type Load } from '../lib/load';
  import { href, queryParam } from '../lib/routes';
  import { PROJECT_STATUS_LABEL, type ProjectDetails } from '../types';

  interface Props {
    /** Адрес проекта. На сайте берётся из ?slug=…, в приложении передаётся явно. */
    slug?: string;
  }

  let { slug }: Props = $props();

  let project = $state<Load<ProjectDetails | null>>(LOADING);
  let docSlug = $state<string | null>(null);

  const doc = $derived.by(() => {
    if (project.state !== 'ready' || !project.data) return null;
    const docs = project.data.docs;
    return docs.find((item) => item.slug === docSlug) ?? docs[0] ?? null;
  });

  async function load(target: string | undefined) {
    if (!isConfigured) {
      project = { state: 'error', message: describeError(new Error('supabase_not_configured')) };
      return;
    }
    if (!target) {
      project = { state: 'ready', data: null };
      return;
    }
    project = LOADING;
    try {
      const data = await getProject(target);
      project = { state: 'ready', data };
      docSlug = null;
      if (data && TARGET === 'web') document.title = `${data.title} — Axo-Team`;
    } catch (error) {
      project = { state: 'error', message: describeError(error) };
    }
  }

  // На сайте экран открывается один раз; в приложении адрес проекта может смениться.
  $effect(() => {
    const target = slug ?? queryParam('slug');
    untrack(() => void load(target));
  });
</script>

<section class="section">
  <div class="container">
    <p class="back"><a href={href({ name: 'projects' })}>← Все проекты</a></p>

    {#if project.state === 'loading'}
      <p class="muted" role="status">Загружаю проект…</p>
    {:else if project.state === 'error'}
      <p class="notice notice--error" role="alert">{project.message}</p>
    {:else if project.data === null}
      <h1 class="page-title">Проект не найден</h1>
      <p class="lead">Такого проекта в каталоге нет. Возможно, он переименован или скрыт.</p>
    {:else}
      {@const data = project.data}
      <header class="head">
        <p class="meta">
          <span class="muted">{data.kind}</span>
          <span class="badge" class:badge--teal={data.status === 'active'} class:badge--warn={data.status === 'experimental'}>
            {PROJECT_STATUS_LABEL[data.status]}
          </span>
          {#if !data.is_published}<span class="badge">Скрыт из каталога</span>{/if}
        </p>
        <h1 class="page-title">{data.title}</h1>
        <p class="lead">{data.summary}</p>

        {#if data.stack.length > 0 || data.license}
          <ul class="facts" aria-label="Технологии и лицензия">
            {#each data.stack as item (item)}
              <li>{item}</li>
            {/each}
            {#if data.license}<li class="license">Лицензия: {data.license}</li>{/if}
          </ul>
        {/if}

        <div class="actions">
          {#each data.links as link (link.id)}
            <a class="button button--ghost" href={link.url} target="_blank" rel="noopener noreferrer">{link.label}</a>
          {/each}
          <a class="button button--ghost" href={href({ name: 'bugs', project: data.slug })}>Сообщить об ошибке</a>
        </div>
      </header>

      {#if data.docs.length > 1}
        <ul class="tabs" aria-label="Страницы документации">
          {#each data.docs as item (item.id)}
            <li>
              <button
                class="tab"
                type="button"
                aria-pressed={doc?.id === item.id}
                onclick={() => (docSlug = item.slug)}>
                {item.title}
              </button>
            </li>
          {/each}
        </ul>
      {/if}

      {#if doc}
        <article class="doc" aria-label={doc.title}>
          <Markdown source={doc.body_md} />
        </article>
      {:else}
        <p class="muted">Документации пока нет.</p>
      {/if}

      <hr />

      {#key data.id}
        <Comments projectId={data.id} />
      {/key}
    {/if}
  </div>
</section>

<style>
  .back {
    margin: 0 0 1.25rem;
    font-size: 0.9375rem;
  }

  .back a {
    text-decoration: none;
  }

  .head {
    margin-bottom: 2rem;
  }

  .meta {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.625rem;
    margin: 0 0 0.5rem;
    font-size: 0.875rem;
  }

  .lead {
    margin: 0 0 1.25rem;
  }

  .facts {
    display: flex;
    flex-wrap: wrap;
    gap: 0.375rem;
    margin: 0 0 1.25rem;
    padding: 0;
    list-style: none;
  }

  .facts li {
    padding: 0.125rem 0.5rem;
    background: var(--axo-surface-raised);
    border-radius: var(--axo-radius-sm);
    font-size: 0.8125rem;
  }

  .facts .license {
    background: none;
    color: var(--axo-muted);
  }

  hr {
    margin: 2.5rem 0;
    border: 0;
    border-top: 1px solid var(--axo-border);
  }
</style>
