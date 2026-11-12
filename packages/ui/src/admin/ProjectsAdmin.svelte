<script lang="ts">
  import { onMount } from 'svelte';
  import { getProject, listProjects } from '../lib/api';
  import { describeError } from '../lib/errors';
  import { LOADING, type Load } from '../lib/load';
  import type { ProjectDetails, ProjectSummary } from '../types';
  import ProjectEditor from './ProjectEditor.svelte';

  type Editing = { mode: 'none' } | { mode: 'new' } | { mode: 'edit'; project: ProjectDetails };

  let projects = $state<Load<ProjectSummary[]>>(LOADING);
  let editing = $state<Editing>({ mode: 'none' });
  let openError = $state<string | null>(null);
  // Меняется, когда выбран другой проект: форма пересоздаётся с его данными.
  let version = $state(0);

  async function loadList() {
    try {
      projects = { state: 'ready', data: await listProjects() };
    } catch (error) {
      projects = { state: 'error', message: describeError(error) };
    }
  }

  /** Перечитывает проект из базы. Форма при этом остаётся той же (несохранённый ввод не теряется). */
  async function refresh(slug: string): Promise<boolean> {
    openError = null;
    try {
      const project = await getProject(slug);
      if (!project) {
        openError = 'Проект не найден. Возможно, он уже удалён.';
        editing = { mode: 'none' };
        return false;
      }
      editing = { mode: 'edit', project };
      return true;
    } catch (error) {
      openError = describeError(error);
      return false;
    }
  }

  /** Открывает другой проект: форма создаётся заново. */
  async function open(slug: string) {
    if (await refresh(slug)) version += 1;
  }

  async function saved(slug: string) {
    await Promise.all([loadList(), refresh(slug)]);
  }

  async function deleted() {
    editing = { mode: 'none' };
    await loadList();
  }

  async function changed() {
    if (editing.mode === 'edit') await refresh(editing.project.slug);
  }

  onMount(loadList);
</script>

<div class="layout">
  <aside>
    <button
      class="button button--small"
      type="button"
      onclick={() => {
        editing = { mode: 'new' };
        version += 1;
      }}>
      + Новый проект
    </button>

    {#if projects.state === 'loading'}
      <p class="muted" role="status">Загружаю…</p>
    {:else if projects.state === 'error'}
      <p class="notice notice--error" role="alert">{projects.message}</p>
    {:else}
      <ul class="list">
        {#each projects.data as project (project.id)}
          <li>
            <button
              class="item"
              type="button"
              aria-pressed={editing.mode === 'edit' && editing.project.id === project.id}
              onclick={() => open(project.slug)}>
              <span>{project.title}</span>
              {#if !project.is_published}<span class="badge">Скрыт</span>{/if}
            </button>
          </li>
        {/each}
      </ul>
    {/if}
  </aside>

  <div class="editor">
    {#if openError}<p class="notice notice--error" role="alert">{openError}</p>{/if}

    {#if editing.mode === 'none'}
      <p class="muted">Выберите проект слева или создайте новый.</p>
    {:else}
      <h2>{editing.mode === 'new' ? 'Новый проект' : editing.project.title}</h2>
      {#key version}
        <ProjectEditor
          project={editing.mode === 'edit' ? editing.project : null}
          onsaved={saved}
          ondeleted={deleted}
          onchange={changed} />
      {/key}
    {/if}
  </div>
</div>

<style>
  .layout {
    display: grid;
    grid-template-columns: minmax(0, 15rem) minmax(0, 1fr);
    gap: 2rem;
    align-items: start;
  }

  aside {
    display: grid;
    gap: 1rem;
    justify-items: start;
  }

  .list {
    display: grid;
    gap: 0.25rem;
    width: 100%;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  .item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.5rem;
    width: 100%;
    padding: 0.5rem 0.75rem;
    background: transparent;
    border: 1px solid transparent;
    border-radius: var(--axo-radius-sm);
    color: var(--axo-text);
    cursor: pointer;
    text-align: left;
  }

  .item:hover {
    background: var(--axo-surface);
  }

  .item[aria-pressed='true'] {
    background: var(--axo-surface-raised);
    border-color: var(--axo-accent);
  }

  h2 {
    margin: 0 0 1.25rem;
    font-size: 1.375rem;
  }

  @media (max-width: 52rem) {
    .layout {
      grid-template-columns: minmax(0, 1fr);
    }
  }
</style>
