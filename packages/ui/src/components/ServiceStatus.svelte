<script lang="ts">
  import { onMount } from 'svelte';
  import { isConfigured, SUPABASE_KEY, SUPABASE_URL } from '../lib/config';
  import { href } from '../lib/routes';

  type Status = 'checking' | 'online' | 'offline' | 'off';

  interface Props {
    timeoutMs?: number;
  }

  let { timeoutMs = 8000 }: Props = $props();

  let status = $state<Status>(isConfigured ? 'checking' : 'off');

  const LABEL: Record<Status, string> = {
    checking: 'проверка…',
    online: 'на связи',
    offline: 'нет ответа',
    off: 'не подключён',
  };

  onMount(() => {
    if (!isConfigured) return;

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);

    fetch(`${SUPABASE_URL}/auth/v1/health`, { headers: { apikey: SUPABASE_KEY }, signal: controller.signal })
      .then((response) => {
        status = response.ok ? 'online' : 'offline';
      })
      .catch(() => {
        status = 'offline';
      })
      .finally(() => clearTimeout(timer));

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  });
</script>

<a class="status" data-status={status} href={href({ name: 'status' })} title="Открыть страницу «Состояние»">
  <span class="dot" aria-hidden="true"></span>
  Сервер: {LABEL[status]}
</a>

<style>
  .status {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    color: var(--axo-muted);
    font-size: 0.8125rem;
    text-decoration: none;
  }

  .status:hover {
    color: var(--axo-text);
  }

  .dot {
    width: 0.5rem;
    height: 0.5rem;
    border-radius: 50%;
    background: var(--axo-muted);
  }

  .status[data-status='online'] .dot {
    background: var(--axo-ok);
  }

  .status[data-status='offline'] .dot {
    background: var(--axo-danger);
  }
</style>
