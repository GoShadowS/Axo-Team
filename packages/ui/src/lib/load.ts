/** Состояние загрузки данных на экране. */
export type Load<T> =
  | { state: 'loading' }
  | { state: 'error'; message: string }
  | { state: 'ready'; data: T };

export const LOADING = { state: 'loading' } as const;
