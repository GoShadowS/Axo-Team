// Переменные сборки, которые читает общий код. Все они публичные:
// значения попадают в клиентский код сайта и приложения.
interface ImportMetaEnv {
  /** Адрес проекта Supabase: https://<ref>.supabase.co */
  readonly PUBLIC_SUPABASE_URL?: string;
  /** Публичный (publishable) ключ Supabase. Секретный ключ сюда нельзя. */
  readonly PUBLIC_SUPABASE_PUBLISHABLE_KEY?: string;
  /** Где собран интерфейс: сайт или ПК-приложение. */
  readonly PUBLIC_AXO_TARGET?: string;
  /** Адрес сайта: на него ведут ссылки из писем Supabase. */
  readonly PUBLIC_AXO_SITE_URL?: string;
  /** Метка сборки: короткий хэш коммита или версия приложения. */
  readonly PUBLIC_AXO_BUILD?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
