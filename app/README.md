# ПК-приложение Axo-Team

Приложение для Windows на Tauri 2. Внутри те же экраны, что на сайте (`packages/ui`), и та же база Supabase: один аккаунт работает и там, и там.

Приложение никуда не публикуется: исходники лежат здесь, установщик собирается из них.

## Что где

```
app/
  index.html, src/        окно приложения: шапка, переключение экранов по адресу после «#»
  src-tauri/              оболочка на Rust: окно, значок, права, настройки установщика
  src-tauri/tauri.conf.json
  src-tauri/capabilities/ что разрешено интерфейсу (только открывать ссылки в браузере)
```

Своей логики в Rust нет: оболочка открывает окно и умеет одно — открыть внешнюю ссылку в браузере пользователя.

## Настройка

```sh
cp app/.env.example app/.env   # значения те же, что в apps/web/.env
```

## Запуск без Rust (в браузере)

```sh
pnpm --filter desktop dev      # http://localhost:1420
```

Так удобно править экраны. Отличие от настоящего окна одно: внешние ссылки открываются в новой вкладке.

## Запуск в окне и сборка установщика

Нужны [Rust](https://rustup.rs) и «Средства сборки C++» из Visual Studio Build Tools. WebView2 в Windows 10 и 11 уже есть.

```sh
pnpm --filter desktop tauri dev     # окно с автообновлением при правках
pnpm --filter desktop tauri build   # установщик в app/src-tauri/target/release/bundle/nsis/
```

После первой сборки появится `app/src-tauri/Cargo.lock` — его нужно закоммитить, чтобы версии Rust-библиотек были одинаковыми у всех.

## Сборка в GitHub Actions

Задача «ПК-приложение — установщик для Windows» в `.github/workflows/ci.yml` собирает установщик, когда меняются `app/` или `packages/ui/`, и кладёт его в артефакты запуска (`axo-team-windows`, хранится 14 дней). Запустить вручную: Actions → CI → Run workflow.

Чтобы собранное приложение было подключено к базе, задай в репозитории две переменные (Settings → Secrets and variables → Actions → Variables): `PUBLIC_SUPABASE_URL` и `PUBLIC_SUPABASE_PUBLISHABLE_KEY`.

## Ограничения

- Установщик не подписан: при первом запуске Windows SmartScreen покажет предупреждение. Сертификат подписи платный.
- Автообновления нет.
- Письмо с подтверждением почты ведёт на сайт. После подтверждения можно входить и в приложении.

## Значок

Исходник — `src-tauri/app-icon.svg` (и он же в PNG 1024×1024). Файлы в `src-tauri/icons/` получены командой:

```sh
pnpm --filter desktop tauri icon src-tauri/app-icon.png
```
