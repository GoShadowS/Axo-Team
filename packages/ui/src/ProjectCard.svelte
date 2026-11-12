<script lang="ts">
  import { PROJECT_STATUS_LABEL, type ProjectSummary } from './types';

  interface Props {
    project: ProjectSummary;
    /** Адрес страницы проекта. */
    href: string;
  }

  let { project, href }: Props = $props();
</script>

<article class="card">
  <header>
    <p class="kind">{project.kind}</p>
    <span class="status" data-status={project.status}>{PROJECT_STATUS_LABEL[project.status]}</span>
  </header>

  <h3><a {href}>{project.title}</a></h3>
  <p class="summary">{project.summary}</p>

  {#if project.stack.length > 0}
    <ul class="stack" aria-label="Технологии">
      {#each project.stack as item (item)}
        <li>{item}</li>
      {/each}
    </ul>
  {/if}
</article>

<style>
  .card {
    position: relative;
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    height: 100%;
    padding: 1.25rem;
    background: var(--axo-surface);
    border: 1px solid var(--axo-border);
    border-radius: var(--axo-radius);
    transition:
      border-color 0.15s ease,
      transform 0.15s ease;
  }

  .card:hover,
  .card:focus-within {
    border-color: var(--axo-accent);
    transform: translateY(-2px);
  }

  header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
  }

  .kind {
    margin: 0;
    color: var(--axo-muted);
    font-size: 0.8125rem;
  }

  .status {
    flex-shrink: 0;
    padding: 0.125rem 0.5rem;
    border: 1px solid currentColor;
    border-radius: 999px;
    color: var(--axo-teal);
    font-size: 0.75rem;
    white-space: nowrap;
  }

  .status[data-status='experimental'] {
    color: var(--axo-warn);
  }

  h3 {
    margin: 0;
    font-size: 1.1875rem;
    line-height: 1.3;
  }

  /* Вся карточка кликабельна, но ссылка в разметке одна. */
  h3 a {
    color: var(--axo-text);
    text-decoration: none;
  }

  h3 a::after {
    content: '';
    position: absolute;
    inset: 0;
    border-radius: var(--axo-radius);
  }

  h3 a:focus-visible {
    outline: none;
  }

  h3 a:focus-visible::after {
    outline: 2px solid var(--axo-accent);
    outline-offset: 2px;
  }

  .summary {
    margin: 0;
    color: var(--axo-muted);
    line-height: 1.55;
  }

  .stack {
    display: flex;
    flex-wrap: wrap;
    gap: 0.375rem;
    margin: auto 0 0;
    padding: 0.25rem 0 0;
    list-style: none;
  }

  .stack li {
    padding: 0.125rem 0.5rem;
    background: var(--axo-surface-raised);
    border-radius: var(--axo-radius-sm);
    color: var(--axo-text);
    font-size: 0.75rem;
  }

  @media (prefers-reduced-motion: reduce) {
    .card {
      transition: none;
    }

    .card:hover,
    .card:focus-within {
      transform: none;
    }
  }
</style>
