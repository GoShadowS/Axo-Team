-- Axo-Team: стартовое наполнение каталога.
-- Описания взяты из README публичных репозиториев владельца.
-- Дальше каталог правится в самой базе; этот файл нужен, чтобы поднять копию с нуля.

with p as (
  insert into public.projects (slug, title, summary, kind, status, stack, license, sort_order)
  values (
    'python-for-minecraft',
    'Python for Minecraft',
    'Языковой мод, который позволяет писать моды для Minecraft на Python — аналог Kotlin for Forge и Fabric Language Kotlin.',
    'Мод для Minecraft',
    'active',
    array['Python', 'NeoForge', 'Fabric'],
    null,
    10
  )
  returning id
),
d as (
  insert into public.docs (project_id, slug, title, body_md, sort_order)
  select id, 'overview', 'Описание', $md$## О проекте

Python for Minecraft — аналог модов «Kotlin for Forge» и «Fabric Language Kotlin», только для модов, написанных на Python.

## Платформы

- Загрузчики: NeoForge и Fabric.
- Версии Minecraft: 1.21.1 и 26.3.
$md$, 10 from p
)
insert into public.links (project_id, label, url, sort_order)
select p.id, v.label, v.url, v.sort_order
from p
cross join (values
  ('Код на GitHub', 'https://github.com/GoShadowS/Python-for-Minecraft', 10)
) as v (label, url, sort_order);

with p as (
  insert into public.projects (slug, title, summary, kind, status, stack, license, sort_order)
  values (
    'create-sable-n-rails',
    'Create: Sable ''n'' Rails',
    'Неофициальный экспериментальный аддон — серверный слой интерактивности для механизмов Create, которые движутся как подуровни Sable.',
    'Аддон для Minecraft',
    'experimental',
    array['Java 21', 'NeoForge', 'Create', 'Sable'],
    'MIT',
    20
  )
  returning id
),
d as (
  insert into public.docs (project_id, slug, title, body_md, sort_order)
  select id, 'overview', 'Описание', $md$## О проекте

Аддон добавляет слой интерактивности с авторитетным сервером для механизмов Create, которые перемещаются как подуровни (sub-levels) Sable.

Это не официальный порт Create: Interactive, и проект не связан с командами Create, Create: Interactive или Sable. Valkyrien Skies он не использует и от него не зависит.

## Платформа

- Minecraft 1.21.1, Java 21.
- Только NeoForge — без Fabric и Forge.

## Состояние

Проект экспериментальный. Что уже реализовано и что ещё не проверено сборкой, подробно расписано в README репозитория.
$md$, 10 from p
)
insert into public.links (project_id, label, url, sort_order)
select p.id, v.label, v.url, v.sort_order
from p
cross join (values
  ('Код на GitHub', 'https://github.com/GoShadowS/Create-Sable-n-Rails', 10)
) as v (label, url, sort_order);

with p as (
  insert into public.projects (slug, title, summary, kind, status, stack, license, sort_order)
  values (
    'retro-time',
    'retro time',
    'Матчевый асимметричный хоррор-выживач для Roblox в стилистике retro-slop.',
    'Игра для Roblox',
    'active',
    array['Roblox', 'R6'],
    null,
    30
  )
  returning id
),
d as (
  insert into public.docs (project_id, slug, title, body_md, sort_order)
  select id, 'overview', 'Описание', $md$## О проекте

retro time — оригинальный матчевый асимметричный хоррор-выживач для Roblox.

- Риг R6 и авторские анимации.
- Визуальное направление — retro-slop: намеренно избыточная стилизация и осознанный коллаж. При этом читаемость персонажей, угроз и важных объектов важнее стиля.
- Платформы: в приоритете PC, мобильные устройства поддерживаются.

## Режимы

| Сервер | Режим | Состав |
|---|---|---|
| Default | Default | 1 убийца против 8 выживших |
| Default | One Bounce | 8 убийц против 1 выжившего |
| Double Trouble | Double Trouble | 2 убийцы против 12 выживших |
| Double Trouble | Two Bounce | 12 убийц против 2 выживших |

One Bounce — неожиданное событие на сервере Default, а не отдельный сервер. Two Bounce — тот же режим в масштабе Double Trouble.
$md$, 10 from p
)
insert into public.links (project_id, label, url, sort_order)
select p.id, v.label, v.url, v.sort_order
from p
cross join (values
  ('Код на GitHub', 'https://github.com/GoShadowS/retro-time', 10)
) as v (label, url, sort_order);

with p as (
  insert into public.projects (slug, title, summary, kind, status, stack, license, sort_order)
  values (
    'logos-guide',
    'Логос',
    'Офлайн-навигатор по зданию колледжа — нативное Android-приложение с картой этажей, поиском помещений и маршрутами без сервера.',
    'Android-приложение',
    'active',
    array['Kotlin', 'Jetpack Compose', 'Material 3', 'Room'],
    'Apache-2.0',
    40
  )
  returning id
),
d as (
  insert into public.docs (project_id, slug, title, body_md, sort_order)
  select id, 'overview', 'Описание', $md$## О проекте

«Логос» — нативное Android-приложение для навигации по зданию АНО ПО «Технический колледж „Логос“». Оно объединяет планы этажей, каталог помещений и маршрутизацию внутри здания.

Карты и данные лежат в самом приложении: для каталога и построения маршрута соединение с сервером не нужно.

## Возможности

- Векторная карта двух этажей с перемещением и масштабированием.
- Интерфейс на русском и английском языках.
- Поиск помещений на двух языках, в том числе по номерам и алиасам.
- Локальная прокладка маршрута, без обращения к серверу.

## Технологии

Kotlin, Jetpack Compose и Material 3. Архитектура — MVVM с репозиториями, `StateFlow`, Room и Preferences DataStore.
$md$, 10 from p
)
insert into public.links (project_id, label, url, sort_order)
select p.id, v.label, v.url, v.sort_order
from p
cross join (values
  ('Код на GitHub', 'https://github.com/GoShadowS/logos-guide', 10)
) as v (label, url, sort_order);
