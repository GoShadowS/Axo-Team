<script lang="ts">
  import { onMount } from 'svelte';
  import { isConfigured } from '../lib/config';
  import { describeError } from '../lib/errors';
  import { go, href, queryParam, safeNext } from '../lib/routes';
  import { session, signUp, startSession } from '../lib/session';
  import { checkDisplayName, checkEmail, checkPassword, firstError, LIMITS } from '../lib/validate';

  interface Props {
    /** Куда вернуться после регистрации. На сайте берётся из ?next=… */
    next?: string;
  }

  let { next }: Props = $props();

  let displayName = $state('');
  let email = $state('');
  let password = $state('');
  let sending = $state(false);
  let formError = $state<string | null>(null);
  let mailSentTo = $state<string | null>(null);
  let back = $state<string | null>(null);

  onMount(() => {
    startSession();
    back = safeNext(next ?? queryParam('next'));
  });

  async function submit(event: SubmitEvent) {
    event.preventDefault();
    formError = firstError(checkDisplayName(displayName), checkEmail(email), checkPassword(password));
    if (formError) return;

    sending = true;
    try {
      const outcome = await signUp({ email, password, displayName });
      if (outcome === 'signed-in') {
        go(back ?? { name: 'account' });
        return;
      }
      mailSentTo = email.trim();
      password = '';
    } catch (error) {
      formError = describeError(error);
    }
    sending = false;
  }
</script>

<section class="section">
  <div class="container narrow">
    <h1 class="page-title">Регистрация</h1>

    {#if !isConfigured}
      <p class="notice notice--error" role="alert">{describeError(new Error('supabase_not_configured'))}</p>
    {:else if mailSentTo}
      <div class="notice notice--ok" role="status">
        <p><strong>Почти готово.</strong> Мы отправили письмо на {mailSentTo}.</p>
        <p>Откройте его и перейдите по ссылке — после этого можно входить на сайте и в приложении.</p>
      </div>
      <p class="actions"><a class="button" href={href({ name: 'login', next: back ?? undefined })}>Перейти ко входу</a></p>
    {:else if $session.user && !sending}
      <p class="notice notice--ok" role="status">
        Вы уже вошли как «{$session.profile?.display_name ?? $session.user.email}».
      </p>
      <p class="actions"><a class="button" href={href({ name: 'account' })}>Мой аккаунт</a></p>
    {:else}
      <p class="lead">Аккаунт нужен, чтобы писать комментарии и отправлять баг-репорты.</p>
      <form class="form" onsubmit={submit} novalidate>
        <label class="field">
          <span>Имя</span>
          <input
            type="text"
            bind:value={displayName}
            autocomplete="nickname"
            maxlength={LIMITS.displayName.max}
            required
            disabled={sending} />
          <small>Его увидят рядом с вашими комментариями. От {LIMITS.displayName.min} до {LIMITS.displayName.max} символов.</small>
        </label>
        <label class="field">
          <span>Почта</span>
          <input type="email" bind:value={email} autocomplete="email" required disabled={sending} />
          <small>Почту никто, кроме вас, не увидит.</small>
        </label>
        <label class="field">
          <span>Пароль</span>
          <input
            type="password"
            bind:value={password}
            autocomplete="new-password"
            maxlength={LIMITS.password.max}
            required
            disabled={sending} />
          <small>Не короче {LIMITS.password.min} символов.</small>
        </label>
        {#if formError}<p class="notice notice--error" role="alert">{formError}</p>{/if}
        <div class="actions">
          <button class="button" type="submit" disabled={sending}>
            {sending ? 'Создаю аккаунт…' : 'Создать аккаунт'}
          </button>
          <span class="muted small">
            Уже есть аккаунт? <a href={href({ name: 'login', next: back ?? undefined })}>Войти</a>
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

  .notice p {
    margin: 0;
  }

  .notice p + p {
    margin-top: 0.5rem;
  }

  .notice + .actions {
    margin-top: 1.25rem;
  }
</style>
