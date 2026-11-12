// @ts-check
import { defineConfig, envField } from 'astro/config';
import svelte from '@astrojs/svelte';

// Метка сборки для страницы «Состояние»: на Vercel это короткий хэш коммита.
const build = (process.env.VERCEL_GIT_COMMIT_SHA ?? '').slice(0, 7) || 'local';

export default defineConfig({
  site: 'https://axo-team.vercel.app',
  output: 'static',
  integrations: [svelte()],
  server: { port: 4321 },
  vite: {
    define: {
      'import.meta.env.PUBLIC_AXO_TARGET': JSON.stringify('web'),
      'import.meta.env.PUBLIC_AXO_BUILD': JSON.stringify(build),
    },
  },
  env: {
    schema: {
      // Оба значения публичные: они попадают в клиентский код.
      // Секретные ключи Supabase сюда добавлять нельзя.
      PUBLIC_SUPABASE_URL: envField.string({
        context: 'client',
        access: 'public',
        optional: true,
        url: true,
      }),
      PUBLIC_SUPABASE_PUBLISHABLE_KEY: envField.string({
        context: 'client',
        access: 'public',
        optional: true,
        startsWith: 'sb_publishable_',
      }),
    },
  },
});
