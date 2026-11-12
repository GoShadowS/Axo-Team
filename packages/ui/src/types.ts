/** Внешняя ссылка проекта: репозиторий, страница загрузки и т. п. */
export interface ProjectLink {
  label: string;
  url: string;
}

/** Состояние проекта в каталоге. */
export type ProjectStatus = 'active' | 'experimental';

/** Карточка проекта в каталоге. Эту же форму будет отдавать API. */
export interface ProjectSummary {
  slug: string;
  title: string;
  summary: string;
  /** Что это: «Мод для Minecraft», «Android-приложение». */
  kind: string;
  status: ProjectStatus;
  stack: string[];
  license?: string;
  links: ProjectLink[];
}

export const PROJECT_STATUS_LABEL: Record<ProjectStatus, string> = {
  active: 'В разработке',
  experimental: 'Эксперимент',
};
