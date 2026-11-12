<script lang="ts">
  import Catalog from '../components/Catalog.svelte';
  import { TARGET } from '../lib/config';
  import { href } from '../lib/routes';

  const features = [
    {
      title: 'Каталог и документация',
      text: 'У каждого проекта есть описание, страницы документации и ссылки на исходный код.',
      link: { label: 'Открыть каталог', route: { name: 'projects' } as const },
    },
    {
      title: 'Комментарии',
      text: 'Войдите в аккаунт и оставьте отзыв или вопрос прямо на странице проекта.',
      link: { label: 'Создать аккаунт', route: { name: 'register' } as const },
    },
    {
      title: 'Баг-репорты',
      text: 'Нашли ошибку — опишите её. У каждого репорта есть номер и понятный статус.',
      link: { label: 'Список ошибок', route: { name: 'bugs' } as const },
    },
  ];
</script>

<section class="hero">
  <div class="container">
    <p class="eyebrow">Портфолио</p>
    <h1>Axo-Team</h1>
    <p class="lead">
      Здесь собраны мои проекты: моды для Minecraft, игра для Roblox и Android-приложение. Один аккаунт
      работает и на сайте, и в приложении для Windows.
    </p>
    <div class="hero__actions">
      <a class="button" href={href({ name: 'projects' })}>Смотреть проекты</a>
      <a class="button button--ghost" href="https://github.com/GoShadowS" rel="noopener">GitHub</a>
    </div>
  </div>
</section>

<section class="section" aria-labelledby="projects-title">
  <div class="container">
    <div class="section-head">
      <h2 id="projects-title">Проекты</h2>
      <a href={href({ name: 'projects' })}>Весь каталог</a>
    </div>
    <Catalog />
  </div>
</section>

<section class="section" aria-labelledby="features-title">
  <div class="container">
    <div class="section-head">
      <h2 id="features-title">Что здесь можно делать</h2>
    </div>
    <ul class="features">
      {#each features as feature (feature.title)}
        <li>
          <h3>{feature.title}</h3>
          <p>{feature.text}</p>
          <a href={href(feature.link.route)}>{feature.link.label}</a>
        </li>
      {/each}
    </ul>
    <p class="muted small where">
      {TARGET === 'desktop'
        ? 'Вы в приложении для Windows. Те же аккаунт и данные доступны на сайте axo-team.vercel.app.'
        : 'Те же аккаунт и данные доступны в приложении для Windows.'}
    </p>
  </div>
</section>

<style>
  .hero {
    padding-block: 3.5rem 1.5rem;
  }

  .eyebrow {
    margin: 0 0 0.5rem;
    color: var(--axo-accent);
    font-size: 0.875rem;
    font-weight: 600;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }

  h1 {
    margin: 0 0 1rem;
    font-size: clamp(2.5rem, 7vw, 3.5rem);
    letter-spacing: -0.02em;
  }

  .hero__actions {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin-top: 1.5rem;
  }

  .features {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(15rem, 1fr));
    gap: 1rem;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  .features li {
    padding: 1.25rem;
    background: var(--axo-surface);
    border: 1px solid var(--axo-border);
    border-radius: var(--axo-radius);
  }

  .features h3 {
    margin: 0 0 0.375rem;
    font-size: 1.0625rem;
  }

  .features p {
    margin: 0 0 0.75rem;
    color: var(--axo-muted);
  }

  .where {
    margin: 1.25rem 0 0;
  }
</style>
