/**
 * Проверка ввода до отправки. Те же границы заданы ограничениями в базе
 * (db/schema.sql): база — последняя инстанция, здесь — понятное сообщение сразу.
 */

export const LIMITS = {
  displayName: { min: 2, max: 40 },
  password: { min: 8, max: 72 },
  comment: { min: 1, max: 2000 },
  bugTitle: { min: 5, max: 120 },
  bugBody: { min: 10, max: 5000 },
  projectTitle: { min: 1, max: 120 },
  projectSummary: { max: 500 },
  projectKind: { max: 80 },
  license: { max: 40 },
  slug: { max: 64 },
  docTitle: { min: 1, max: 120 },
  docBody: { max: 100_000 },
  linkLabel: { min: 1, max: 80 },
  url: { max: 2000 },
} as const;

/** Убирает пробелы по краям и схлопывает повторы внутри. */
export function cleanName(value: string): string {
  return value.replace(/\s+/g, ' ').trim();
}

type Check = string | null;

function length(value: string, min: number, max: number, what: string): Check {
  if (value.length < min) {
    return min === 1 ? `${what}: поле не заполнено.` : `${what}: не короче ${min} символов.`;
  }
  if (value.length > max) return `${what}: не длиннее ${max} символов (сейчас ${value.length}).`;
  return null;
}

export function checkDisplayName(value: string): Check {
  return length(cleanName(value), LIMITS.displayName.min, LIMITS.displayName.max, 'Имя');
}

export function checkEmail(value: string): Check {
  const email = value.trim();
  if (email === '') return 'Почта: поле не заполнено.';
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return 'Почта: адрес выглядит неправильно.';
  }
  return null;
}

export function checkPassword(value: string): Check {
  return length(value, LIMITS.password.min, LIMITS.password.max, 'Пароль');
}

export function checkComment(value: string): Check {
  return length(value.trim(), LIMITS.comment.min, LIMITS.comment.max, 'Комментарий');
}

export function checkBugTitle(value: string): Check {
  return length(value.trim(), LIMITS.bugTitle.min, LIMITS.bugTitle.max, 'Заголовок');
}

export function checkBugBody(value: string): Check {
  return length(value.trim(), LIMITS.bugBody.min, LIMITS.bugBody.max, 'Описание');
}

export function checkSlug(value: string): Check {
  if (value === '') return 'Адрес (slug): поле не заполнено.';
  if (value.length > LIMITS.slug.max || !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(value)) {
    return 'Адрес (slug): только строчные латинские буквы, цифры и дефис, например my-project.';
  }
  return null;
}

export function checkUrl(value: string): Check {
  const url = value.trim();
  if (url.length > LIMITS.url.max || !/^https?:\/\/\S+$/.test(url)) {
    return 'Ссылка: нужен полный адрес, который начинается с https:// или http://.';
  }
  return null;
}

export function checkText(value: string, min: number, max: number, what: string): Check {
  return length(value.trim(), min, max, what);
}

/** Первая найденная ошибка или null, если всё в порядке. */
export function firstError(...checks: Check[]): Check {
  return checks.find((check) => check !== null) ?? null;
}
