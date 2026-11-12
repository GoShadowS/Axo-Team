import { derived, get, writable, type Readable } from 'svelte/store';
import type { Profile } from '../types';
import { fetchProfile, updateDisplayName } from './api';
import { getClient } from './client';
import { isConfigured, SITE_URL } from './config';
import { AxoError } from './errors';
import { cleanName } from './validate';

export interface SessionUser {
  id: string;
  email: string;
}

export interface SessionState {
  /** true, когда уже известно, вошёл ли посетитель, и его профиль загружен. */
  ready: boolean;
  user: SessionUser | null;
  profile: Profile | null;
}

const store = writable<SessionState>({ ready: false, user: null, profile: null });

let started = false;

/**
 * Текущий аккаунт. Одинаково работает на сайте и в приложении.
 * Слежение за сессией включается само при первом обращении.
 */
export const session: Readable<SessionState> = {
  subscribe(run, invalidate) {
    startSession();
    return store.subscribe(run, invalidate);
  },
};

/** Владелец сайта? Это только для показа кнопок: права проверяет база. */
export const isAdmin = derived(session, ($session) => $session.profile?.role === 'admin');

/** Чей профиль сейчас загружается: Supabase присылает несколько событий подряд, запрос нужен один. */
let loadingFor: string | null = null;

async function loadProfile(userId: string): Promise<void> {
  if (loadingFor === userId) return;
  loadingFor = userId;
  // undefined — профиль не удалось прочитать (нет сети): остаётся то, что было известно раньше.
  let profile: Profile | null | undefined;
  try {
    profile = await fetchProfile(userId);
  } catch {
    profile = undefined;
  } finally {
    loadingFor = null;
  }
  store.update((state) =>
    state.user?.id === userId
      ? { ...state, ready: true, profile: profile === undefined ? state.profile : profile }
      : state,
  );
}

/**
 * Перечитывает профиль из базы. Нужно приложению: оно не перезагружается между экранами,
 * а роль могла измениться, пока оно открыто.
 */
export async function refreshProfile(): Promise<void> {
  const { user, profile } = get(store);
  // Профиль ещё не загружен — он загрузится сам, второй запрос не нужен.
  if (!user || !profile) return;
  await loadProfile(user.id);
}

function apply(user: SessionUser | null): void {
  const previous = get(store);
  if (!user) {
    store.set({ ready: true, user: null, profile: null });
    return;
  }
  if (previous.user?.id === user.id && previous.profile) {
    if (previous.user.email !== user.email) store.set({ ...previous, user });
    return;
  }
  if (previous.user?.id !== user.id) store.set({ ready: false, user, profile: null });
  // Запросы к Supabase нельзя делать прямо внутри обработчика входа — только после него.
  setTimeout(() => void loadProfile(user.id), 0);
}

/** Запускает слежение за сессией. Можно вызывать сколько угодно раз. */
export function startSession(): void {
  if (started || typeof window === 'undefined') return;
  started = true;

  if (!isConfigured) {
    store.set({ ready: true, user: null, profile: null });
    return;
  }

  getClient().auth.onAuthStateChange((_event, current) => {
    apply(current?.user ? { id: current.user.id, email: current.user.email ?? '' } : null);
  });
}

export type SignUpOutcome = 'signed-in' | 'confirm-email';

/** Регистрация. Профиль с именем создаёт база (триггер on_auth_user_created). */
export async function signUp(input: {
  email: string;
  password: string;
  displayName: string;
}): Promise<SignUpOutcome> {
  const { data, error } = await getClient().auth.signUp({
    email: input.email.trim(),
    password: input.password,
    options: {
      data: { display_name: cleanName(input.displayName) },
      emailRedirectTo: `${SITE_URL}/login/?confirmed=1`,
    },
  });
  if (error) throw error;
  // Для занятой почты Supabase отвечает «успехом» без identities, чтобы не выдавать чужие адреса.
  if (data.user && !data.session && (data.user.identities?.length ?? 0) === 0) {
    throw new AxoError('Аккаунт с такой почтой уже есть. Войдите или используйте другую почту.');
  }
  return data.session ? 'signed-in' : 'confirm-email';
}

export async function signIn(email: string, password: string): Promise<void> {
  const { error } = await getClient().auth.signInWithPassword({ email: email.trim(), password });
  if (error) throw error;
}

export async function signOut(): Promise<void> {
  const { error } = await getClient().auth.signOut({ scope: 'local' });
  if (error) throw error;
}

export async function changePassword(password: string): Promise<void> {
  const { error } = await getClient().auth.updateUser({ password });
  if (error) throw error;
}

/** Меняет имя в профиле и сразу обновляет его на экране. */
export async function renameSelf(displayName: string): Promise<void> {
  const user = get(store).user;
  if (!user) throw new AxoError('Сессия закончилась. Войдите снова.');
  const profile = await updateDisplayName(user.id, cleanName(displayName));
  store.update((state) => (state.user?.id === user.id ? { ...state, profile } : state));
}
