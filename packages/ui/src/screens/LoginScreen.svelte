<script lang="ts">
  import { onMount } from 'svelte';
  import { isConfigured } from '../lib/config';
  import { describeError } from '../lib/errors';
  import { go, href, queryParam, safeNext } from '../lib/routes';
  import { session, signIn, startSession } from '../lib/session';
  import { checkEmail, firstError } from '../lib/validate';

  interface Props {
    /** Куда вернуться после входа. На сайте берётся из ?next=… */
    next?: string;
  }

  let { next }: Props = $props();

  let email = $state('');
  let password = $state('');
  let sending = $state(false);
  let formError = $state<string | null>(null);
  let confirmed = $state(false);
  let back = $state<string | null>(null);

  onMount(() => {
    startSession();
    back = safeNext(next ?? queryParam('next'));
    confirmed = queryParam('confirmed') === '1';
  });

  async function submit(event: SubmitEvent) {
    event.preventDefault();
    formError = firstError(checkEmail(email), password === '' ? 'Пароль: поле не заполнено.' : null);
    if (formError) return;

    sending = true;
    try {
      await signIn(email, password);
      go(back ?? { name: 'account' });
    } catch (error) {
      formError = describeError(error);
      sending = false;
    }
  }
</script>

<section class="section">
  <div class="container narrow">
    <h1 class="page-title">Вход</h1>

    {#if !isConfigured}
      <p class="notice notice--error" role="alert">{describeError(new Error('supabase_not_configured'))}</p>
    {:else if $session.user && !sending}
      <p class="notice notice--ok" role="status">
        {confirmed ? 'Почта подтверждена. ' : ''}Вы вошли как «{$session.profile?.display_name ?? $session.user.email}».
      </p>
      <p class="actions">
        <a class="button" href={back ?? href({ name: 'account' })}>{back ? 'Продолжить' : 'Мой аккаунт'}</a>
        <a class="button button--ghost" href={href({ name: 'projects' })}>К проектам</a>
      </p>
    {:else}
      <p class="lead">Один аккаунт для сайта и приложения для Windows.</p>
      {#if confirmed}
        <p class="notice notice--ok" role="status">Почта подтверждена. Теперь можно войти.</p>
      {/if}
      <form class="form" onsubmit={submit} novalidate>
        <label class="field">
          <span>Почта</span>
          <input type="email" bind:value={email} autocomplete="email" required disabled={sending} />
        </label>
        <label class="field">
          <span>Пароль</span>
          <input type="password" bind:value={password} autocomplete="current-password" required disabled={sending} />
        </label>
        {#if formError}<p class="notice notice--error" role="alert">{formError}</p>{/if}
        <div class="actions">
          <button class="button" type="submit" disabled={sending}>{sending ? 'Вхожу…' : 'Войти'}</button>
          <span class="muted small">
            Нет аккаунта? <a href={href({ name: 'register', next: back ?? undefined })}>Регистрация</a>
          </span>
        </div>
      </form>
    {/if}
  </div>
</section>

<style>
  .narrow {
    max-width: 34rem;
  }

  .lead {
    margin: 0 0 1.5rem;
  }

  .notice + .form,
  .notice + .actions {
    margin-top: 1.25rem;
  }
</style>
