<script lang="ts">
  import { onMount } from 'svelte';

  type Status = 'checking' | 'online' | 'offline';

  interface Props {
    /** Адрес проекта Supabase, например https://<ref>.supabase.co */
    supabaseUrl: string;
    /** Публичный (publishable) ключ. Секретный ключ сюда передавать нельзя. */
    publishableKey: string;
    timeoutMs?: number;
  }

  let { supabaseUrl, publishableKey, timeoutMs = 8000 }: Props = $props();

  let status = $state<Status>('checking');

  const LABEL: Record<Status, string> = {
    checking: 'проверка…',
    online: 'на связи',
    offline: 'нет ответа',
  };

  onMount(() => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    const endpoint = `${supabaseUrl.replace(/\/+$/, '')}/auth/v1/health`;

    fetch(endpoint, { headers: { apikey: publishableKey }, signal: controller.signal })
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

<p class="status" data-status={status} role="status">
  <span class="dot" aria-hidden="true"></span>
  Supabase: {LABEL[status]}
</p>

<style>
  .status {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    margin: 0;
    color: var(--axo-muted);
    font-size: 0.8125rem;
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
