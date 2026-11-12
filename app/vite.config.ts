import { readFileSync } from 'node:fs';
import { svelte } from '@sveltejs/vite-plugin-svelte';
import { defineConfig } from 'vite';

const { version } = JSON.parse(readFileSync(new URL('./package.json', import.meta.url), 'utf8')) as {
  version: string;
};

// Tauri задаёт эту переменную, когда приложение запускают на другом устройстве в сети.
const host = process.env.TAURI_DEV_HOST;

export default defineConfig({
  plugins: [svelte()],
  // Те же имена переменных, что у сайта: PUBLIC_SUPABASE_URL и PUBLIC_SUPABASE_PUBLISHABLE_KEY.
  envPrefix: ['VITE_', 'PUBLIC_'],
  define: {
    'import.meta.env.PUBLIC_AXO_TARGET': JSON.stringify('desktop'),
    'import.meta.env.PUBLIC_AXO_BUILD': JSON.stringify(`v${version}`),
  },
  // Tauri ждёт интерфейс на фиксированном порту и сам показывает ошибки Rust.
  clearScreen: false,
  server: {
    port: 1420,
    strictPort: true,
    host: host || '0.0.0.0',
    watch: { ignored: ['**/src-tauri/**'] },
  },
  build: {
    // Окно приложения в Windows — это WebView2 (Chromium).
    target: 'chrome111',
    outDir: 'dist',
    emptyOutDir: true,
  },
});
