import { getCollection, type CollectionEntry } from 'astro:content';
import type { ProjectSummary } from '@axo/ui';

export type ProjectEntry = CollectionEntry<'projects'>;

/** Все проекты каталога в порядке показа. */
export async function getProjects(): Promise<ProjectEntry[]> {
  const entries = await getCollection('projects');
  return entries.sort(
    (a, b) => a.data.order - b.data.order || a.data.title.localeCompare(b.data.title, 'ru'),
  );
}

export function toSummary(entry: ProjectEntry): ProjectSummary {
  const { title, summary, kind, status, stack, license, links } = entry.data;
  return { slug: entry.id, title, summary, kind, status, stack, license, links };
}

export function projectHref(entry: ProjectEntry): string {
  return `/projects/${entry.id}/`;
}
