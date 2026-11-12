<script lang="ts">
  import { onMount } from 'svelte';
  import { countRows } from '../lib/api';
  import { BUILD_LABEL, isConfigured, SUPABASE_KEY, SUPABASE_URL, TARGET } from '../lib/config';
  import { describeError } from '../lib/errors';
  import { session, startSession } from '../lib/session';

  type State = 'checking' | 'ok' | 'fail' | 'skip';

  interface Check {
    state: State;
    detail: string;
  }

  const CHECKING: Check = { state: 'checking', detail: 'проверяю…' };

  let auth = $state<Check>(CHECKING);
  let database = $state<Check>(CHECKING);
  let checkedAt = $state<string | null>(null);
  let running = $state(false);

  const LABEL: Record<State, string> = { checking: '…', ok: 'Работает', fail: 'Не работает', skip: 'Пропущено' };

  const config = $derived<Check>(
    isConfigured
      ? { state: 'ok', detail: new URL(SUPABASE_URL).host }
      : { state: 'fail', detail: 'сборка сделана без PUBLIC_SUPABASE_URL и PUBLIC_SUPABASE_PUBLISHABLE_KEY' },
  );

  const account = $derived<Check>(
    !$session.ready
      ? CHECKING
      : $session.user
        ? { state: 'ok', detail: `вы вошли как «${$session.profile?.display_name ?? $session.user.email}»` }
        : { state: 'skip', detail: 'вы не вошли в аккаунт' },
  );

  const ms = (from: number) => `${Math.round(performance.now() - from)} мс`;

  async function checkAuth(): Promise<Check> {
    const started = performance.now();
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 8000);
    try {
      const response = await fetch(`${SUPABASE_URL}/auth/v1/health`, {
        headers: { apikey: SUPABASE_KEY },
        signal: controller.signal,
      });
      return response.ok
        ? { state: 'ok', detail: `ответ за ${ms(started)}` }
        : { state: 'fail', detail: `сервер ответил кодом ${response.status}` };
    } catch {
      return { state: 'fail', detail: 'нет ответа за 8 секунд' };
    } finally {
      clearTimeout(timer);
    }
  }

  async function checkDatabase(): Promise<Check> {
    const started = performance.now();
    try {
      const rows = await countRows();
      return {
        state: 'ok',
        detail: `ответ за ${ms(started)} · проектов: ${rows.projects}, комментариев: ${rows.comments}, репортов: ${rows.bugs}`,
      };
    } catch (error) {
      return { state: 'fail', detail: describeError(error) };
    }
  }

  async function run() {
    if (!isConfigured) {
      auth = { state: 'skip', detail: 'нет настроек подключения' };
      database = { state: 'skip', detail: 'нет настроек подключения' };
      return;
    }
    running = true;
    auth = CHECKING;
    database = CHECKING;
    [auth, database] = await Promise.all([checkAuth(), checkDatabase()]);
    checkedAt = new Date().toLocaleTimeString('ru-RU');
    running = false;
  }

  onMount(() => {
    startSession();
    void run();
  });
</script>

{#snippet row(title: string, what: string, check: Check)}
  <li class="panel check" data-state={check.state}>
    <span class="dot" aria-hidden="true"></span>
    <div>
      <h2>{title}</h2>
      <p class="muted small">{what}</p>
    </div>
    <p class="result">
      <strong>{LABEL[check.state]}</strong>
      <span class="muted small">{check.detail}</span>
    </p>
  </li>
{/snippet}

<section class="section">
  <div class="container">
    <h1 class="page-title">Состояние</h1>
    <p class="lead">Живая проверка: страница прямо сейчас обращается к серверу и показывает, что ответило.</p>

    <ul class="stack-list" aria-live="polite">
      {@render row('Подключение', 'Адрес и публичный ключ Supabase в этой сборке', config)}
      {@render row('Аккаунты', 'Сервис входа и регистрации (Supabase Auth)', auth)}
      {@render row('База данных', 'Чтение каталога, комментариев и репортов', database)}
      {@render row('Ваша сессия', 'Аккаунт, под которым открыта страница', account)}
    </ul>

    <div class="actions foot">
      <button class="button button--ghost" type="button" onclick={run} disabled={running}>
        {running ? 'Проверяю…' : 'Проверить ещё раз'}
      </button>
      <span class="muted small">
        {checkedAt ? `Проверено в ${checkedAt}. ` : ''}{TARGET === 'desktop' ? 'Приложение' : 'Сайт'}, сборка {BUILD_LABEL}.
      </span>
    </div>
  </div>
</section>

<style>
  .lead {
    margin: 0 0 1.75rem;
  }

  .check {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr) minmax(0, 1fr);
    gap: 0.25rem 1rem;
    align-items: center;
  }

  h2 {
    margin: 0;
    font-size: 1.0625rem;
  }

  .check p {
    margin: 0;
  }

  .result {
    display: grid;
    justify-items: end;
    text-align: right;
  }

  .dot {
    width: 0.75rem;
    height: 0.75rem;
    border-radius: 50%;
    background: var(--axo-muted);
  }

  .check[data-state='ok'] .dot {
    background: var(--axo-ok);
  }

  .check[data-state='ok'] strong {
    color: var(--axo-ok);
  }

  .check[data-state='fail'] .dot {
    background: var(--axo-danger);
  }

  .check[data-state='fail'] strong {
    color: var(--axo-danger);
  }

  .foot {
    margin-top: 1.5rem;
  }

  @media (max-width: 40rem) {
    .check {
      grid-template-columns: auto minmax(0, 1fr);
    }

    .result {
      grid-column: 2;
      justify-items: start;
      text-align: left;
    }
  }
</style>
