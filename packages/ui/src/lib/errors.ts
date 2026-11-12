/** Перевод ошибок Supabase в понятные сообщения. */

interface ErrorLike {
  message?: unknown;
  code?: unknown;
  status?: unknown;
  hint?: unknown;
  name?: unknown;
}

const AUTH_MESSAGES: Record<string, string> = {
  invalid_credentials: 'Неверная почта или пароль.',
  email_not_confirmed: 'Почта ещё не подтверждена. Откройте письмо и перейдите по ссылке.',
  user_already_exists: 'Аккаунт с такой почтой уже есть. Войдите или используйте другую почту.',
  email_exists: 'Аккаунт с такой почтой уже есть. Войдите или используйте другую почту.',
  weak_password: 'Пароль слишком простой. Сделайте его длиннее.',
  same_password: 'Новый пароль совпадает со старым.',
  signup_disabled: 'Регистрация сейчас закрыта.',
  email_provider_disabled: 'Регистрация по почте сейчас закрыта.',
  email_address_invalid: 'Такой адрес почты не принимается. Проверьте, нет ли опечатки.',
  email_address_not_authorized:
    'На этот адрес сейчас нельзя отправить письмо с подтверждением. Сообщите владельцу сайта.',
  over_email_send_rate_limit: 'Слишком много писем за короткое время. Попробуйте через час.',
  over_request_rate_limit: 'Слишком много попыток. Подождите несколько минут.',
  session_not_found: 'Сессия закончилась. Войдите снова.',
  session_expired: 'Сессия закончилась. Войдите снова.',
  user_banned: 'Аккаунт заблокирован.',
};

const DB_MESSAGES: Record<string, string> = {
  '42501': 'Недостаточно прав для этого действия.',
  '23505': 'Такое значение уже занято.',
  '23503': 'Связанная запись не найдена. Обновите страницу.',
  '23514': 'Значение не проходит проверку: слишком короткое, длинное или в неверном формате.',
  PGRST116: 'Запись не найдена.',
  PGRST301: 'Сессия закончилась. Войдите снова.',
};

export class AxoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AxoError';
  }
}

/** Сообщение для пользователя по любой пойманной ошибке. */
export function describeError(error: unknown): string {
  if (error instanceof AxoError) return error.message;

  const e: ErrorLike = typeof error === 'object' && error !== null ? (error as ErrorLike) : {};
  const message = typeof e.message === 'string' ? e.message : '';
  const code = typeof e.code === 'string' ? e.code : '';

  if (message === 'supabase_not_configured') {
    return 'Сборка сделана без адреса и ключа Supabase, поэтому данные недоступны.';
  }
  if (message.includes('rate_limit_exceeded')) {
    return typeof e.hint === 'string' && e.hint !== ''
      ? e.hint
      : 'Слишком много записей за короткое время. Подождите немного.';
  }
  if (code in AUTH_MESSAGES) return AUTH_MESSAGES[code] as string;
  if (code in DB_MESSAGES) return DB_MESSAGES[code] as string;
  if (e.name === 'AuthRetryableFetchError' || /failed to fetch|networkerror|load failed/i.test(message)) {
    return 'Нет связи с сервером. Проверьте интернет и попробуйте ещё раз.';
  }
  if (e.status === 429) return 'Слишком много запросов. Подождите немного.';

  return message !== '' ? `Не получилось: ${message}` : 'Не получилось выполнить действие. Попробуйте ещё раз.';
}
