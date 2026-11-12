import DOMPurify from 'dompurify';
import { marked } from 'marked';

let hooked = false;

function addLinkHook(): void {
  if (hooked) return;
  hooked = true;
  // Внешние ссылки открываются отдельно и не получают доступ к нашей вкладке.
  DOMPurify.addHook('afterSanitizeAttributes', (node) => {
    if (node instanceof HTMLAnchorElement && /^https?:/i.test(node.getAttribute('href') ?? '')) {
      node.setAttribute('target', '_blank');
      node.setAttribute('rel', 'noopener noreferrer');
    }
  });
}

/**
 * Markdown → безопасный HTML. Работает только в браузере.
 * Текст приходит из базы, поэтому всё, что может выполнить код, вырезается.
 */
export function renderMarkdown(source: string): string {
  addLinkHook();
  const html = marked.parse(source, { async: false, gfm: true });
  return DOMPurify.sanitize(html, {
    USE_PROFILES: { html: true },
    FORBID_TAGS: ['style', 'form', 'input', 'button', 'textarea', 'select', 'iframe'],
    FORBID_ATTR: ['style'],
  });
}
