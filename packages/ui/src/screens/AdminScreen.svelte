<script lang="ts">
  import CommentsAdmin from '../admin/CommentsAdmin.svelte';
  import ProjectsAdmin from '../admin/ProjectsAdmin.svelte';
  import { isConfigured } from '../lib/config';
  import { describeError } from '../lib/errors';
  import { href } from '../lib/routes';
  import { isAdmin, refreshProfile, session } from '../lib/session';
  import { onMount } from 'svelte';
  import BugsScreen from './BugsScreen.svelte';

  type Tab = 'projects' | 'comments' | 'bugs';

  const TABS: { id: Tab; label: string }[] = [
    { id: 'projects', label: 'Проекты' },
    { id: 'comments', label: 'Комментарии' },
    { id: 'bugs', label: 'Баг-репорты' },
  ];

  let tab = $state<Tab>('projects');

  // Права владельца выдаются в базе; экран берёт свежую роль, а не ту, что запомнил при входе.
  onMount(() => {
    void refreshProfile();
  });
</script>

<section class="section">
  <div class="container">
    <h1 class="page-title">Админка</h1>

    {#if !isConfigured}
      <p class="notice notice--error" role="alert">{describeError(new Error('supabase_not_configured'))}</p>
    {:else if !$session.ready}
      <p class="muted" role="status">Проверяю права…</p>
    {:else if !$session.user}
      <p class="notice notice--info">Админка доступна только владельцу. Сначала войдите в аккаунт.</p>
      <p class="actions gap"><a class="button" href={href({ name: 'login', next: href({ name: 'admin' }) })}>Войти</a></p>
    {:else if !$isAdmin}
      <!-- Это только отказ в показе. Настоящая защита — RLS: без роли admin база не примет ни одной правки. -->
      <p class="notice notice--error" role="alert">У этого аккаунта нет прав владельца.</p>
    {:else}
      <p class="lead">Каталог, документация и модерация. Изменения сразу видны на сайте и в приложении.</p>

      <ul class="tabs" aria-label="Разделы админки">
        {#each TABS as item (item.id)}
          <li>
            <button class="tab" type="button" aria-pressed={tab === item.id} onclick={() => (tab = item.id)}>
              {item.label}
            </button>
          </li>
        {/each}
      </ul>

      {#if tab === 'projects'}
        <ProjectsAdmin />
      {:else if tab === 'comments'}
        <CommentsAdmin />
      {:else}
        <BugsScreen embedded />
      {/if}
    {/if}
  </div>
</section>

<style>
  .lead {
    margin: 0 0 1.5rem;
  }

  .gap {
    margin-top: 1.25rem;
  }
</style>
