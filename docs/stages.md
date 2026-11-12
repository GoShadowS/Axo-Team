# Этапы и состояние

Порядок взят из roadmap в Google Doc «Стек проекта: Rust + Astro + Tauri 2».

## Этап 1. Репозиторий и сайт — сделан

- pnpm-монорепо: `apps/web`, `packages/ui`.
- Сайт на Astro (SSG) с островом на Svelte: главная, каталог, страница проекта, 404.
- Каталог читается из Markdown-файлов в `apps/web/src/content/projects/`.
- CI в GitHub Actions: `pnpm -r check` и сборка сайта.

## Этап 2. Схема базы в Supabase — не начат

Таблицы `projects`, `docs`, `links`, `comments`, `bugs`, `users`; RLS и политика в той же миграции. Перед применением нужен план миграции и подтверждение владельца.

## Этап 3. API на Rust (Axum + SQLx) — не начат

Rust в песочнице агента не собирается, поэтому `cargo clippy` и `cargo test -p api` запускаются в GitHub Actions или на машине владельца.

## Этап 4. Админка — не начата

## Этап 5. ПК-приложение на Tauri 2 — не начато

Установщик собирается в GitHub Actions на `windows-latest`.

## Этап 6. Контент и публикация — не начат
