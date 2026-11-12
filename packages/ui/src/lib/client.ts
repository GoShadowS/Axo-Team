import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { isConfigured, SUPABASE_KEY, SUPABASE_URL, TARGET } from './config';

let client: SupabaseClient | undefined;

/**
 * Единственный клиент Supabase на страницу.
 * Работает с публичным ключом: всё, что можно и нельзя, решают RLS-политики в базе.
 */
export function getClient(): SupabaseClient {
  if (!isConfigured) {
    throw new Error('supabase_not_configured');
  }
  client ??= createClient(SUPABASE_URL, SUPABASE_KEY, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      // Письмо с подтверждением ведёт на сайт; приложение ссылки не принимает.
      detectSessionInUrl: TARGET === 'web',
      storageKey: 'axo-team-auth',
    },
  });
  return client;
}
