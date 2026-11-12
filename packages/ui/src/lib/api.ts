/**
 * Все обращения к данным в одном месте. Запросы идут прямо в Supabase
 * с публичным ключом; что разрешено, решают RLS-политики (db/schema.sql).
 */
import type { PostgrestError } from '@supabase/supabase-js';
import type {
  Bug,
  BugStatus,
  Comment,
  DocInput,
  LinkInput,
  Profile,
  ProjectDetails,
  ProjectDoc,
  ProjectInput,
  ProjectLink,
  ProjectSummary,
} from '../types';
import { getClient } from './client';
import { AxoError } from './errors';

const PROJECT_COLUMNS = 'id,slug,title,summary,kind,status,stack,license,sort_order,is_published';
const DOC_COLUMNS = 'id,slug,title,body_md,sort_order';
const LINK_COLUMNS = 'id,label,url,sort_order';
const PROFILE_COLUMNS = 'id,display_name,role,created_at';
const COMMENT_COLUMNS = 'id,project_id,author_id,body,is_hidden,created_at,author:users(display_name,role)';
const BUG_COLUMNS =
  'id,number,project_id,author_id,title,body,status,is_hidden,created_at,updated_at,author:users(display_name,role),project:projects(slug,title)';

const NO_ACCESS = 'Недостаточно прав для этого действия, или запись уже удалена.';

interface Result<T> {
  data: T | null;
  error: PostgrestError | null;
}

/** Ошибка запроса становится исключением; сообщение для экрана даёт describeError. */
function unwrap<T>(result: Result<T>): T {
  if (result.error) throw result.error;
  if (result.data === null) throw new AxoError('Сервер вернул пустой ответ.');
  return result.data;
}

/**
 * RLS не отвечает ошибкой, когда правка запрещена: запрос просто не затрагивает строк.
 * Поэтому каждая правка просит вернуть изменённые строки и проверяет, что они есть.
 */
function expectRows<T>(result: Result<T[]>): T[] {
  const rows = unwrap(result);
  if (rows.length === 0) throw new AxoError(NO_ACCESS);
  return rows;
}

// --- Профиль ---------------------------------------------------------------

export async function fetchProfile(userId: string): Promise<Profile | null> {
  const result = await getClient().from('users').select(PROFILE_COLUMNS).eq('id', userId).maybeSingle();
  if (result.error) throw result.error;
  return result.data as Profile | null;
}

export async function updateDisplayName(userId: string, displayName: string): Promise<Profile> {
  const result = await getClient()
    .from('users')
    .update({ display_name: displayName })
    .eq('id', userId)
    .select(PROFILE_COLUMNS);
  return expectRows(result as Result<Profile[]>)[0] as Profile;
}

// --- Каталог ---------------------------------------------------------------

/** Проекты в порядке показа. Гость и пользователь получают только опубликованные. */
export async function listProjects(): Promise<ProjectSummary[]> {
  const result = await getClient()
    .from('projects')
    .select(PROJECT_COLUMNS)
    .order('sort_order', { ascending: true })
    .order('title', { ascending: true });
  return unwrap(result as Result<ProjectSummary[]>);
}

/** Проект с документами и ссылками или null, если такого адреса нет. */
export async function getProject(slug: string): Promise<ProjectDetails | null> {
  const result = await getClient()
    .from('projects')
    .select(`${PROJECT_COLUMNS},docs(${DOC_COLUMNS}),links(${LINK_COLUMNS})`)
    .eq('slug', slug)
    .order('sort_order', { referencedTable: 'docs', ascending: true })
    .order('sort_order', { referencedTable: 'links', ascending: true })
    .maybeSingle();
  if (result.error) throw result.error;
  return result.data as ProjectDetails | null;
}

// --- Комментарии -----------------------------------------------------------

export async function listComments(projectId: string): Promise<Comment[]> {
  const result = await getClient()
    .from('comments')
    .select(COMMENT_COLUMNS)
    .eq('project_id', projectId)
    .order('created_at', { ascending: false })
    .limit(200);
  return unwrap(result as unknown as Result<Comment[]>);
}

/** Последние комментарии по всем проектам (для админки). */
export async function listRecentComments(): Promise<Comment[]> {
  const result = await getClient()
    .from('comments')
    .select(`${COMMENT_COLUMNS},project:projects(slug,title)`)
    .order('created_at', { ascending: false })
    .limit(100);
  return unwrap(result as unknown as Result<Comment[]>);
}

/** Автора подставляет база по сессии; клиент присылает только проект и текст. */
export async function addComment(projectId: string, body: string): Promise<Comment> {
  const result = await getClient()
    .from('comments')
    .insert({ project_id: projectId, body })
    .select(COMMENT_COLUMNS)
    .single();
  return unwrap(result as unknown as Result<Comment>);
}

export async function setCommentHidden(id: string, hidden: boolean): Promise<void> {
  const result = await getClient().from('comments').update({ is_hidden: hidden }).eq('id', id).select('id');
  expectRows(result as Result<{ id: string }[]>);
}

export async function deleteComment(id: string): Promise<void> {
  const result = await getClient().from('comments').delete().eq('id', id).select('id');
  expectRows(result as Result<{ id: string }[]>);
}

// --- Баг-репорты -----------------------------------------------------------

export async function listBugs(filter: { status?: BugStatus; projectId?: string } = {}): Promise<Bug[]> {
  let request = getClient().from('bugs').select(BUG_COLUMNS);
  if (filter.status) request = request.eq('status', filter.status);
  if (filter.projectId) request = request.eq('project_id', filter.projectId);
  const result = await request.order('created_at', { ascending: false }).limit(200);
  return unwrap(result as unknown as Result<Bug[]>);
}

export async function addBug(input: { projectId: string | null; title: string; body: string }): Promise<Bug> {
  const result = await getClient()
    .from('bugs')
    .insert({ project_id: input.projectId, title: input.title, body: input.body })
    .select(BUG_COLUMNS)
    .single();
  return unwrap(result as unknown as Result<Bug>);
}

export async function setBugStatus(id: string, status: BugStatus): Promise<void> {
  const result = await getClient().from('bugs').update({ status }).eq('id', id).select('id');
  expectRows(result as Result<{ id: string }[]>);
}

export async function setBugHidden(id: string, hidden: boolean): Promise<void> {
  const result = await getClient().from('bugs').update({ is_hidden: hidden }).eq('id', id).select('id');
  expectRows(result as Result<{ id: string }[]>);
}

export async function deleteBug(id: string): Promise<void> {
  const result = await getClient().from('bugs').delete().eq('id', id).select('id');
  expectRows(result as Result<{ id: string }[]>);
}

// --- Админка: проекты, документы, ссылки -------------------------------------

export async function createProject(input: ProjectInput): Promise<ProjectSummary> {
  const result = await getClient().from('projects').insert(input).select(PROJECT_COLUMNS).single();
  return unwrap(result as Result<ProjectSummary>);
}

export async function updateProject(id: string, input: ProjectInput): Promise<ProjectSummary> {
  const result = await getClient().from('projects').update(input).eq('id', id).select(PROJECT_COLUMNS);
  return expectRows(result as Result<ProjectSummary[]>)[0] as ProjectSummary;
}

/** Вместе с проектом база удаляет его документы, ссылки и комментарии. */
export async function deleteProject(id: string): Promise<void> {
  const result = await getClient().from('projects').delete().eq('id', id).select('id');
  expectRows(result as Result<{ id: string }[]>);
}

export async function createDoc(projectId: string, input: DocInput): Promise<ProjectDoc> {
  const result = await getClient()
    .from('docs')
    .insert({ project_id: projectId, ...input })
    .select(DOC_COLUMNS)
    .single();
  return unwrap(result as Result<ProjectDoc>);
}

export async function updateDoc(id: string, input: DocInput): Promise<ProjectDoc> {
  const result = await getClient().from('docs').update(input).eq('id', id).select(DOC_COLUMNS);
  return expectRows(result as Result<ProjectDoc[]>)[0] as ProjectDoc;
}

export async function deleteDoc(id: string): Promise<void> {
  const result = await getClient().from('docs').delete().eq('id', id).select('id');
  expectRows(result as Result<{ id: string }[]>);
}

export async function createLink(projectId: string, input: LinkInput): Promise<ProjectLink> {
  const result = await getClient()
    .from('links')
    .insert({ project_id: projectId, ...input })
    .select(LINK_COLUMNS)
    .single();
  return unwrap(result as Result<ProjectLink>);
}

export async function updateLink(id: string, input: LinkInput): Promise<ProjectLink> {
  const result = await getClient().from('links').update(input).eq('id', id).select(LINK_COLUMNS);
  return expectRows(result as Result<ProjectLink[]>)[0] as ProjectLink;
}

export async function deleteLink(id: string): Promise<void> {
  const result = await getClient().from('links').delete().eq('id', id).select('id');
  expectRows(result as Result<{ id: string }[]>);
}

// --- Состояние сервисов ------------------------------------------------------

export interface TableCounts {
  projects: number;
  comments: number;
  bugs: number;
}

/** Сколько записей видит текущий посетитель. Заодно проверяет, что база отвечает. */
export async function countRows(): Promise<TableCounts> {
  const client = getClient();
  const count = async (table: string): Promise<number> => {
    const result = await client.from(table).select('id', { count: 'exact', head: true });
    if (result.error) throw result.error;
    return result.count ?? 0;
  };
  const [projects, comments, bugs] = await Promise.all([count('projects'), count('comments'), count('bugs')]);
  return { projects, comments, bugs };
}
