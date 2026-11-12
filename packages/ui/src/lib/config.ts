/** Настройки сборки. Читаются один раз; секретов здесь нет и быть не должно. */

const trim = (value: string | undefined): string => (value ?? '').trim();

export const SUPABASE_URL = trim(import.meta.env.PUBLIC_SUPABASE_URL).replace(/\/+$/, '');
export const SUPABASE_KEY = trim(import.meta.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY);

/** false, если сборка сделана без адреса и ключа Supabase. */
export const isConfigured = SUPABASE_URL !== '' && SUPABASE_KEY !== '';

export type Target = 'web' | 'desktop';
export const TARGET: Target = import.meta.env.PUBLIC_AXO_TARGET === 'desktop' ? 'desktop' : 'web';

export const SITE_URL = (trim(import.meta.env.PUBLIC_AXO_SITE_URL) || 'https://axo-team.vercel.app').replace(
  /\/+$/,
  '',
);

export const BUILD_LABEL = trim(import.meta.env.PUBLIC_AXO_BUILD) || 'local';
