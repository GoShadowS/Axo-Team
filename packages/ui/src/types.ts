/** Формы данных: то, что отдаёт база (Supabase) сайту и приложению. */

/** Состояние проекта в каталоге. */
export type ProjectStatus = 'active' | 'experimental';

export const PROJECT_STATUS_LABEL: Record<ProjectStatus, string> = {
  active: 'В разработке',
  experimental: 'Эксперимент',
};

/** Внешняя ссылка проекта: репозиторий, страница загрузки и т. п. */
export interface ProjectLink {
  id: string;
  label: string;
  url: string;
  sort_order: number;
}

/** Страница документации проекта в Markdown. */
export interface ProjectDoc {
  id: string;
  slug: string;
  title: string;
  body_md: string;
  sort_order: number;
}

/** Карточка проекта в каталоге. */
export interface ProjectSummary {
  id: string;
  slug: string;
  title: string;
  summary: string;
  /** Что это: «Мод для Minecraft», «Android-приложение». */
  kind: string;
  status: ProjectStatus;
  stack: string[];
  license: string | null;
  sort_order: number;
  is_published: boolean;
}

/** Проект целиком: карточка, документы и ссылки. */
export interface ProjectDetails extends ProjectSummary {
  docs: ProjectDoc[];
  links: ProjectLink[];
}

export type UserRole = 'user' | 'admin';

/** Профиль аккаунта (таблица users). Почта и пароль хранятся в Supabase Auth. */
export interface Profile {
  id: string;
  display_name: string;
  role: UserRole;
  created_at: string;
}

export interface AuthorRef {
  display_name: string;
  role?: UserRole;
}

export interface ProjectRef {
  slug: string;
  title: string;
}

export interface Comment {
  id: string;
  project_id: string;
  author_id: string;
  body: string;
  is_hidden: boolean;
  created_at: string;
  author: AuthorRef | null;
  /** Заполняется только в общем списке админки. */
  project?: ProjectRef | null;
}

export type BugStatus = 'new' | 'confirmed' | 'in_progress' | 'fixed' | 'rejected';

export const BUG_STATUSES: readonly BugStatus[] = ['new', 'confirmed', 'in_progress', 'fixed', 'rejected'];

export const BUG_STATUS_LABEL: Record<BugStatus, string> = {
  new: 'Новый',
  confirmed: 'Подтверждён',
  in_progress: 'В работе',
  fixed: 'Исправлен',
  rejected: 'Отклонён',
};

export interface Bug {
  id: string;
  number: number;
  project_id: string | null;
  author_id: string;
  title: string;
  body: string;
  status: BugStatus;
  is_hidden: boolean;
  created_at: string;
  updated_at: string;
  author: AuthorRef | null;
  project: ProjectRef | null;
}

/** Поля проекта, которые заполняет владелец в админке. */
export interface ProjectInput {
  slug: string;
  title: string;
  summary: string;
  kind: string;
  status: ProjectStatus;
  stack: string[];
  license: string | null;
  sort_order: number;
  is_published: boolean;
}

export interface DocInput {
  slug: string;
  title: string;
  body_md: string;
  sort_order: number;
}

export interface LinkInput {
  label: string;
  url: string;
  sort_order: number;
}
