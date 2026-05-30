# AppPoc — Copilot Instructions

## Architecture

Application desktop hybride combinant trois couches :

- **Frontend** (`src/`) : SvelteKit 2 + Svelte 5 + TypeScript, compilé en SPA statique (adapter-static)
- **Backend** (`backend/`) : Symfony 8.0 + API Platform 4.3 + Doctrine ORM 3, PHP 8.4
- **Desktop** (`src-tauri/`) : Tauri v2, Rust (edition 2021)

Le backend PHP tourne via **FrankenPHP** embarqué comme sidecar Tauri. En production, le binaire FrankenPHP est bundlé avec les fichiers backend dans les ressources Tauri. En dev, FrankenPHP est lancé manuellement ou via le Makefile.

## Ports et communication

- Frontend Vite dev server : `localhost:1420`
- Backend FrankenPHP : `127.0.0.1:8080`
- Le frontend communique avec le backend via `fetch()` sur `http://127.0.0.1:8080/api/`
- L'API expose du JSON-LD (`application/ld+json`) et du JSON (`application/json`)

## Base de données

- SQLite via l'extension `pdo_sqlite`
- Doctrine ORM avec mapping par **attributs PHP 8** (pas d'annotations)
- Migrations Doctrine dans `backend/migrations/`

## Environnement de développement

- **Docker** : image basée sur `dunglas/frankenphp:1-php8.4-bookworm` (voir `Dockerfile`)
- **WSLg** : support display X11/Wayland pour lancer Tauri depuis le container
- **Package manager** : pnpm (workspace à la racine)
- **Commandes Makefile** :
  - `make up` / `make down` : démarrer/arrêter les containers
  - `make dev` : lance FrankenPHP + `pnpm tauri dev`
  - `make bash` : shell dans le container
  - `make install` : `pnpm install`
  - `make database-init` : `doctrine:schema:create`

## Conventions générales

- Les entités Doctrine sont dans `backend/src/Entity/` et sont directement décorées avec `#[ApiResource()]` pour les exposer via API Platform
- Les repositories sont dans `backend/src/Repository/`
- Le frontend utilise la syntaxe **Svelte 5 runes** (`$state`, `$effect`, `$derived`, etc.)
- SSR désactivé (`export const ssr = false` dans `+layout.ts`)
- TypeScript strict activé
