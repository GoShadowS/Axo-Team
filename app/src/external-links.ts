import { openUrl } from '@tauri-apps/plugin-opener';

const insideTauri = (): boolean => '__TAURI_INTERNALS__' in window;

/**
 * Окно приложения показывает только сам интерфейс. Любая внешняя ссылка
 * (GitHub, ссылки из документации) открывается в браузере пользователя.
 */
export function openExternalLinksInBrowser(): void {
  document.addEventListener('click', (event) => {
    if (event.defaultPrevented || !(event.target instanceof Element)) return;

    const anchor = event.target.closest('a[href]');
    if (!(anchor instanceof HTMLAnchorElement)) return;

    const url = new URL(anchor.href, window.location.href);
    if (url.origin === window.location.origin) return;

    event.preventDefault();
    if (url.protocol !== 'https:' && url.protocol !== 'http:' && url.protocol !== 'mailto:') return;

    if (insideTauri()) {
      void openUrl(url.href);
    } else {
      // Интерфейс открыт в обычном браузере (pnpm --filter desktop dev).
      window.open(url.href, '_blank', 'noopener,noreferrer');
    }
  });
}
