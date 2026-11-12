# Открытые решения

Здесь то, что должен решить владелец. Пока решения нет, действует [AGENTS.md](../AGENTS.md).

## Хостинг сайта: Cloudflare Pages или Vercel

- В `AGENTS.md` указан Cloudflare Pages.
- В Google Doc (разделы 1, 3, 5 и roadmap) указан Vercel.
- Проект в Vercel уже создан и привязан к репозиторию, поэтому превью сайта сейчас собирается там.

Сайт полностью статический, привязки к хостингу в коде нет. Единственный файл, который относится к Vercel, — `apps/web/vercel.json` с заголовками кэша.

## Кэш API: Redis или `moka`

- В `AGENTS.md`: без Redis, `moka` в процессе.
- В Google Doc (раздел 1 и «Неделя 3»): Redis.

## Хостинг API: Render Free или Fly.io/Railway

- В `AGENTS.md` и разделе 8 Google Doc: Render Free.
- В разделе 7 Google Doc: Fly.io или Railway.

## Видимость репозитория и лицензия

`AGENTS.md` и Google Doc рассчитывают на публичный репозиторий с лицензией MIT. Сейчас репозиторий приватный и без лицензии.
