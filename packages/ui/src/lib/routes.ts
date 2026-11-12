import { TARGET } from './config';

/**
 * Экраны, общие для сайта и приложения.
 * На сайте это отдельные страницы, в приложении — адреса после «#».
 */
export type Route =
  | { name: 'home' }
  | { name: 'projects' }
  | { name: 'project'; slug: string }
  | { name: 'bugs'; project?: string }
  | { name: 'login'; next?: string }
  | { name: 'register'; next?: string }
  | { name: 'account' }
  | { name: 'admin' }
  | { name: 'status' }
  | { name: 'not-found' };

export type RouteName = Route['name'];

const WEB_PATH: Record<Exclude<RouteName, 'not-found'>, string> = {
  home: '/',
  projects: '/projects/',
  project: '/project/',
  bugs: '/bugs/',
  login: '/login/',
  register: '/register/',
  account: '/account/',
  admin: '/admin/',
  status: '/status/',
};

function query(params: Record<string, string | undefined>): string {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value) search.set(key, value);
  }
  const text = search.toString();
  return text ? `?${text}` : '';
}

function routeParams(route: Route): Record<string, string | undefined> {
  switch (route.name) {
    case 'project':
      return { slug: route.slug };
    case 'bugs':
      return { project: route.project };
    case 'login':
    case 'register':
      return { next: route.next };
    default:
      return {};
  }
}

/** Адрес экрана для текущей сборки. */
export function href(route: Route): string {
  if (route.name === 'not-found') return TARGET === 'desktop' ? '#/' : '/';
  const path = WEB_PATH[route.name];
  const suffix = query(routeParams(route));
  return TARGET === 'desktop' ? `#${path.replace(/(.)\/$/, '$1')}${suffix}` : `${path}${suffix}`;
}

/** Адрес, на котором пользователь находится сейчас (чтобы вернуться после входа). */
export function currentHref(): string {
  if (typeof window === 'undefined') return href({ name: 'home' });
  return TARGET === 'desktop'
    ? window.location.hash || '#/'
    : `${window.location.pathname}${window.location.search}`;
}

/**
 * Проверка адреса возврата: только свой адрес внутри сайта или приложения.
 * Чужой адрес (https://..., //host) отбрасывается.
 */
export function safeNext(next: string | null | undefined): string | null {
  if (!next) return null;
  const ok = TARGET === 'desktop' ? /^#\//.test(next) : /^\/(?![/\\])/.test(next);
  return ok ? next : null;
}

/** Переход на экран или на готовый внутренний адрес. */
export function go(target: Route | string): void {
  const address = typeof target === 'string' ? target : href(target);
  if (TARGET === 'desktop') {
    window.location.hash = address.replace(/^#/, '');
  } else {
    window.location.assign(address);
  }
}

/** Разбор адреса приложения вида «#/project?slug=retro-time». */
export function parseHash(hash: string): Route {
  const [rawPath = '', rawQuery = ''] = hash.replace(/^#/, '').split('?');
  const path = `/${rawPath.replace(/^\/+|\/+$/g, '')}`;
  const params = new URLSearchParams(rawQuery);
  const value = (key: string) => params.get(key) ?? undefined;

  switch (path) {
    case '/':
      return { name: 'home' };
    case '/projects':
      return { name: 'projects' };
    case '/project': {
      const slug = value('slug');
      return slug ? { name: 'project', slug } : { name: 'projects' };
    }
    case '/bugs':
      return { name: 'bugs', project: value('project') };
    case '/login':
      return { name: 'login', next: value('next') };
    case '/register':
      return { name: 'register', next: value('next') };
    case '/account':
      return { name: 'account' };
    case '/admin':
      return { name: 'admin' };
    case '/status':
      return { name: 'status' };
    default:
      return { name: 'not-found' };
  }
}

/** Параметр из адреса страницы сайта. В приложении параметры приходят свойствами. */
export function queryParam(name: string): string | undefined {
  if (typeof window === 'undefined' || TARGET === 'desktop') return undefined;
  return new URLSearchParams(window.location.search).get(name) ?? undefined;
}
