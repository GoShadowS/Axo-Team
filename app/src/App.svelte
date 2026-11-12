<script lang="ts">
  import { BUILD_LABEL, href, parseHash, type Route, type RouteName } from '@axo/ui';
  import ServiceStatus from '@axo/ui/components/ServiceStatus.svelte';
  import UserMenu from '@axo/ui/components/UserMenu.svelte';
  import AccountScreen from '@axo/ui/screens/AccountScreen.svelte';
  import AdminScreen from '@axo/ui/screens/AdminScreen.svelte';
  import BugsScreen from '@axo/ui/screens/BugsScreen.svelte';
  import HomeScreen from '@axo/ui/screens/HomeScreen.svelte';
  import LoginScreen from '@axo/ui/screens/LoginScreen.svelte';
  import NotFoundScreen from '@axo/ui/screens/NotFoundScreen.svelte';
  import ProjectScreen from '@axo/ui/screens/ProjectScreen.svelte';
  import ProjectsScreen from '@axo/ui/screens/ProjectsScreen.svelte';
  import RegisterScreen from '@axo/ui/screens/RegisterScreen.svelte';
  import StatusScreen from '@axo/ui/screens/StatusScreen.svelte';
  import { onMount } from 'svelte';
  import Logo from './Logo.svelte';

  // Экран выбирается по адресу после «#»: так работают «назад» и «вперёд», а ссылки общие с сайтом.
  let hash = $state(window.location.hash);
  const route = $derived<Route>(parseHash(hash));

  const nav: { route: Route; label: string; active: RouteName[] }[] = [
    { route: { name: 'home' }, label: 'Главная', active: ['home'] },
    { route: { name: 'projects' }, label: 'Проекты', active: ['projects', 'project'] },
    { route: { name: 'bugs' }, label: 'Баг-репорты', active: ['bugs'] },
    { route: { name: 'status' }, label: 'Состояние', active: ['status'] },
  ];

  onMount(() => {
    const onHashChange = () => {
      hash = window.location.hash;
      window.scrollTo(0, 0);
    };
    window.addEventListener('hashchange', onHashChange);
    return () => window.removeEventListener('hashchange', onHashChange);
  });
</script>

<a class="skip-link" href="#main" onclick={(event) => {
  event.preventDefault();
  document.getElementById('main')?.focus();
}}>К содержанию</a>

<header class="app-header">
  <div class="container app-header__inner">
    <a class="brand" href={href({ name: 'home' })}>
      <Logo />
      <span>Axo-Team</span>
    </a>
    <nav aria-label="Основная навигация">
      <ul>
        {#each nav as item (item.label)}
          <li>
            <a href={href(item.route)} aria-current={item.active.includes(route.name) ? 'page' : undefined}>
              {item.label}
            </a>
          </li>
        {/each}
      </ul>
    </nav>
    <div class="account">
      <UserMenu />
    </div>
  </div>
</header>

<main id="main" tabindex="-1">
  <!-- Экран создаётся заново при каждом переходе: формы и списки не тянут старое состояние. -->
  {#key hash}
    {#if route.name === 'home'}
      <HomeScreen />
    {:else if route.name === 'projects'}
      <ProjectsScreen />
    {:else if route.name === 'project'}
      <ProjectScreen slug={route.slug} />
    {:else if route.name === 'bugs'}
      <BugsScreen project={route.project} />
    {:else if route.name === 'login'}
      <LoginScreen next={route.next} />
    {:else if route.name === 'register'}
      <RegisterScreen next={route.next} />
    {:else if route.name === 'account'}
      <AccountScreen />
    {:else if route.name === 'admin'}
      <AdminScreen />
    {:else if route.name === 'status'}
      <StatusScreen />
    {:else}
      <NotFoundScreen />
    {/if}
  {/key}
</main>

<footer class="app-footer">
  <div class="container app-footer__inner">
    <p>Axo-Team для Windows · {BUILD_LABEL}</p>
    <div class="meta">
      <ServiceStatus />
      <a href="https://axo-team.vercel.app">Сайт</a>
      <a href="https://github.com/GoShadowS">GitHub</a>
    </div>
  </div>
</footer>

<style>
  .app-header {
    position: sticky;
    top: 0;
    z-index: 5;
    background: var(--axo-bg);
    border-bottom: 1px solid var(--axo-border);
  }

  .app-header__inner {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.25rem 1.5rem;
    min-height: 3.75rem;
    padding-block: 0.5rem;
  }

  .brand {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    color: var(--axo-text);
    font-weight: 700;
    text-decoration: none;
  }

  nav ul {
    display: flex;
    flex-wrap: wrap;
    gap: 0.25rem;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  nav a {
    display: block;
    padding: 0.375rem 0.75rem;
    border-radius: 999px;
    color: var(--axo-muted);
    font-size: 0.9375rem;
    text-decoration: none;
  }

  nav a:hover {
    color: var(--axo-text);
  }

  nav a[aria-current='page'] {
    background: var(--axo-surface-raised);
    color: var(--axo-text);
  }

  .account {
    margin-left: auto;
  }

  main {
    flex: 1;
    outline: none;
  }

  .app-footer {
    margin-top: 3rem;
    border-top: 1px solid var(--axo-border);
    color: var(--axo-muted);
    font-size: 0.875rem;
  }

  .app-footer__inner {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem 1.5rem;
    padding-block: 1.25rem;
  }

  .app-footer p {
    margin: 0;
  }

  .meta {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.75rem 1.5rem;
  }
</style>
