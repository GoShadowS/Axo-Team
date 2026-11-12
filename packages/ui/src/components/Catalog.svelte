<script lang="ts">
  import { onMount } from 'svelte';
  import { listProjects } from '../lib/api';
  import { isConfigured } from '../lib/config';
  import { describeError } from '../lib/errors';
  import { LOADING, type Load } from '../lib/load';
  import { href } from '../lib/routes';
  import type { ProjectSummary } from '../types';
  import ProjectCard from './ProjectCard.svelte';

  let projects = $state<Load<ProjectSummary[]>>(LOADING);

  async function load() {
    projects = LOADING;
    try {
      projects = { state: 'ready', data: await listProjects() };
    } catch (error) {
      projects = { state: 'error', message: describeError(error) };
    }
  }

  onMount(() => {
    if (isConfigured) void load();
    else projects = { state: 'error', message: describeError(new Error('supabase_not_configured')) };
  });
</script>

{#if projects.state === 'loading'}
  <p class="muted" role="status">Загружаю каталог…</p>
{:else if projects.state === 'error'}
  <div class="notice notice--error" role="alert">
    <p>{projects.message}</p>
    {#if isConfigured}
      <p><button class="button button--ghost button--small" type="button" onclick={load}>Повторить</button></p>
    {/if}
  </div>
{:else if projects.data.length === 0}
  <p class="notice notice--info">В каталоге пока нет проектов.</p>
{:else}
  <ul class="grid">
    {#each projects.data as project (project.id)}
      <li>
        <ProjectCard {project} href={href({ name: 'project', slug: project.slug })} />
      </li>
    {/each}
  </ul>
{/if}

<style>
  .notice p {
    margin: 0;
  }

  .notice p + p {
    margin-top: 0.625rem;
  }
</style>
