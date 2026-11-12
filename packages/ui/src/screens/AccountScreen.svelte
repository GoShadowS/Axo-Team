<script lang="ts">
  import { onMount } from 'svelte';
  import { isConfigured } from '../lib/config';
  import { describeError } from '../lib/errors';
  import { formatDate } from '../lib/format';
  import { go, href } from '../lib/routes';
  import { changePassword, isAdmin, renameSelf, session, signOut, startSession } from '../lib/session';
  import { checkDisplayName, checkPassword, cleanName, LIMITS } from '../lib/validate';

  let displayName = $state('');
  let nameBusy = $state(false);
  let nameError = $state<string | null>(null);
  let nameSaved = $state(false);

  let password = $state('');
  let passwordBusy = $state(false);
  let passwordError = $state<string | null>(null);
  let passwordSaved = $state(false);

  let filledFor: string | null = null;

  onMount(startSession);

  // Имя подставляется в форму один раз, когда профиль загрузился.
  $effect(() => {
    const profile = $session.profile;
    if (profile && filledFor !== profile.id) {
      filledFor = profile.id;
      displayName = profile.display_name;
    }
  });

  async function saveName(event: SubmitEvent) {
    event.preventDefault();
    nameSaved = false;
    nameError = checkDisplayName(displayName);
    if (nameError) return;

    nameBusy = true;
    try {
      await renameSelf(displayName);
      displayName = cleanName(displayName);
      nameSaved = true;
    } catch (error) {
      nameError = describeError(error);
    } finally {
      nameBusy = false;
    }
  }

  async function savePassword(event: SubmitEvent) {
    event.preventDefault();
    passwordSaved = false;
    passwordError = checkPassword(password);
    if (passwordError) return;

    passwordBusy = true;
    try {
      await changePassword(password);
      password = '';
      passwordSaved = true;
    } catch (error) {
      passwordError = describeError(error);
    } finally {
      passwordBusy = false;
    }
  }

  async function leave() {
    try {
      await signOut();
      go({ name: 'home' });
    } catch (error) {
      nameError = describeError(error);
    }
  }
</script>

<section class="section">
  <div class="container narrow">
    <h1 class="page-title">Мой аккаунт</h1>

    {#if !isConfigured}
      <p class="notice notice--error" role="alert">{describeError(new Error('supabase_not_configured'))}</p>
    {:else if !$session.ready}
      <p class="muted" role="status">Проверяю аккаунт…</p>
    {:else if !$session.user}
      <p class="notice notice--info">Вы не вошли в аккаунт.</p>
      <p class="actions">
        <a class="button" href={href({ name: 'login' })}>Войти</a>
        <a class="button button--ghost" href={href({ name: 'register' })}>Регистрация</a>
      </p>
    {:else}
      <dl class="panel facts">
        <div>
          <dt>Почта</dt>
          <dd>{$session.user.email}</dd>
        </div>
        <div>
          <dt>Роль</dt>
          <dd>
            {#if $isAdmin}
              Владелец · <a href={href({ name: 'admin' })}>открыть админку</a>
            {:else}
              Пользователь
            {/if}
          </dd>
        </div>
        {#if $session.profile}
          <div>
            <dt>Зарегистрирован</dt>
            <dd>{formatDate($session.profile.created_at)}</dd>
          </div>
        {/if}
      </dl>

      <h2>Имя</h2>
      <form class="form" onsubmit={saveName} novalidate>
        <label class="field">
          <span>Как вас показывать</span>
          <input
            type="text"
            bind:value={displayName}
            autocomplete="nickname"
            maxlength={LIMITS.displayName.max}
            required
            disabled={nameBusy} />
        </label>
        {#if nameError}<p class="notice notice--error" role="alert">{nameError}</p>{/if}
        {#if nameSaved}<p class="notice notice--ok" role="status">Имя сохранено.</p>{/if}
        <div class="actions">
          <button class="button" type="submit" disabled={nameBusy}>{nameBusy ? 'Сохраняю…' : 'Сохранить имя'}</button>
        </div>
      </form>

      <h2>Пароль</h2>
      <form class="form" onsubmit={savePassword} novalidate>
        <label class="field">
          <span>Новый пароль</span>
          <input
            type="password"
            bind:value={password}
            autocomplete="new-password"
            maxlength={LIMITS.password.max}
            required
            disabled={passwordBusy} />
          <small>Не короче {LIMITS.password.min} символов.</small>
        </label>
        {#if passwordError}<p class="notice notice--error" role="alert">{passwordError}</p>{/if}
        {#if passwordSaved}<p class="notice notice--ok" role="status">Пароль изменён.</p>{/if}
        <div class="actions">
          <button class="button button--ghost" type="submit" disabled={passwordBusy}>
            {passwordBusy ? 'Меняю…' : 'Сменить пароль'}
          </button>
        </div>
      </form>

      <h2>Выход</h2>
      <p class="muted">Вы выйдете только на этом устройстве.</p>
      <p><button class="button button--danger" type="button" onclick={leave}>Выйти из аккаунта</button></p>
    {/if}
  </div>
</section>

<style>
  .narrow {
    max-width: 34rem;
  }

  h2 {
    margin: 2rem 0 0.875rem;
    font-size: 1.25rem;
  }

  .facts {
    display: grid;
    gap: 0.75rem;
    margin: 1.25rem 0 0;
  }

  .facts div {
    display: grid;
    grid-template-columns: 9.5rem 1fr;
    gap: 0.75rem;
  }

  dt {
    color: var(--axo-muted);
  }

  dd {
    margin: 0;
    overflow-wrap: anywhere;
  }

  .notice + .actions {
    margin-top: 1.25rem;
  }
</style>
