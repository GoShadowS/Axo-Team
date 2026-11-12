import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

// Временный источник каталога: Markdown-файлы в репозитории.
// Когда появится API, страницы начнут читать те же поля оттуда
// (тип ProjectSummary в packages/ui).
const projects = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/projects' }),
  schema: z.object({
    title: z.string(),
    summary: z.string(),
    kind: z.string(),
    status: z.enum(['active', 'experimental']),
    stack: z.array(z.string()).default([]),
    license: z.string().optional(),
    links: z
      .array(z.object({ label: z.string(), url: z.url() }))
      .default([]),
    order: z.number().int().default(100),
  }),
});

export const collections = { projects };
