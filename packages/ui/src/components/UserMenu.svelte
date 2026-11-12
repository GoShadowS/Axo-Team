<script lang="ts">
  import { onMount } from 'svelte';
  import { describeError } from '../lib/errors';
  import { go, href } from '../lib/routes';
  import { isAdmin, session, signOut, startSession } from '../lib/session';

  let busy = $state(false);

  onMount(startSession);

  const name = $derived($session.profile?.display_name ?? $session.user?.email ?? '');

  async function leave() {
    busy = true;
    try {
      await signOut();
      go({ name: 'home' });
    } catch (error) {
      alert(describeError(error));
    } finally {
      busy = false;
    }
  }
</script>

<div class="menu" aria-live="polite">
  {#if !$session.ready && !$session.user}
    <span class="muted small">…</span>
  {:else if $session.user}
    {#if $isAdmin}
      <a href={href({ name: 'admin' })}>Админка</a>
    {/if}
    <a class="who" href={href({ name: 'account' })} title="Мой аккаунт">{name}</a>
    <button class="link-button" type="button" onclick={leave} disabled={busy}>Выйти</button>
  {:else}
    <a href={href({ name: 'login' })}>Войти</a>
    <a class="button button--small" href={href({ name: 'register' })}>Регистрация</a>
  {/if}
</div>

<style>
  .menu {
    display: flex;
    align-items: center;
    gap: 0.875rem;
    min-height: 2rem;
    font-size: 0.9375rem;
    white-space: nowrap;
  }

  a:not(.button) {
    color: var(--axo-muted);
    text-decoration: none;
  }

  a:not(.button):hover {
    color: var(--axo-text);
  }

  .who {
    max-width: 11rem;
    overflow: hidden;
    color: var(--axo-text) !important;
    font-weight: 600;
    text-overflow: ellipsis;
  }

  .link-button {
    color: var(--axo-muted);
    text-decoration: none;
  }

  .link-button:hover {
    color: var(--axo-text);
  }
</style>
