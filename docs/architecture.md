# Mix-Me Architecture

Mix-Me is a thin orchestration and customization layer on top of two upstream projects:

- **[Hermes Agent](https://github.com/NousResearch/hermes-agent)** — the AI agent framework that handles natural-language intent, memory, scheduling, and subagents.
- **[Hermes playlist tooling](https://github.com/GodSpoon/hermes)** — our Python package that searches Qobuz, downloads tracks, scrapes radio charts, and writes M3U8 playlists.

Both are included as git submodules so Mix-Me always pins compatible versions and can be deployed as a single clone.

## Components

### 1. Hermes Agent (`hermes-agent/` submodule)

Hermes Agent is the entry point for conversational interaction. A user can say:

> "Make me a deathcore/hyperpop playlist with 25 tracks and sync it to my iPod."

Hermes Agent loads the `mix-me` skill, which tells it how to translate that intent into calls against the Hermes tooling.

### 2. Mix-Me skill (`skills/mix-me/`)

The skill contains:

- `SKILL.md` — frontmatter, triggers, and procedures for Hermes Agent.
- `scripts/mixme_client.py` — a thin wrapper around the Hermes CLI so the skill can call it without hard-coding paths. `scripts/install.sh` exposes this as `.venv/bin/mixme`.

The skill is exposed to Hermes Agent by adding the `skills/` directory to `skills.external_dirs` in Hermes Agent's `config.yaml`:

```bash
hermes config set skills.external_dirs /path/to/Mix-Me/skills
```

(Older docs suggested `hermes skills install /path/to/Mix-Me/skills/mix-me`, but current Hermes Agent versions only support URL/git identifiers for `skills install`; local skills are loaded via `external_dirs`.)

### 3. Hermes tooling (`hermes/` submodule)

The core Python package provides:

- `hermes.cli propose` — generate a draft from genres / radio cache / taste data.
- `hermes.cli run` — run a built-in or custom recipe.
- `hermes.cli finalize` — download tracks, write M3U8, optionally sync.
- `hermes.cli web` — launch the conversational web UI.
- `hermes/scripts/refresh_radio_cache.py` — scrape college-radio charts.
- `hermes/scripts/weekly_college_radio.sh` — weekly scheduled refresh.

### 4. Configuration (`config/`)

User-specific settings live outside the submodules:

- `config/hermes.yaml` — music root, Qobuz binary, Spotify DB, sync profiles, radio sources, recipes, Plex.
- `config/recipes.yaml` — custom recipe definitions that can be merged into `hermes.yaml`.

## Data flow

```
User request
    │
    ▼
Hermes Agent + mix-me skill
    │
    ▼
mixme_client.py  ──►  hermes.cli propose / run / finalize
    │
    ▼
hermes Python package
    │
    ├── Spotify DB (libSQL)  ──► taste seeds
    ├── Radio chart scraper  ──► KEXP / KCRW / BBC6 / NACC / WFUV / KUTX
    ├── Qobuz search/dl      ──► FLAC/MP3 files
    └── MusicBrainz          ──► album/year metadata
    │
    ▼
M3U8 playlist + synced devices + Plex playlist
```

## Customization

Because upstream code lives in submodules, all personal customizations belong in `Mix-Me/config/` or `Mix-Me/scripts/`:

- Add new radio sources in `config/hermes.yaml` under `radio_sources:`.
- Add new recipes in `config/recipes.yaml` and merge them into `hermes.yaml`.
- Override sync profiles for your specific Rockbox/Plexamp setup.
- Fork `scripts/weekly_college_radio.sh` if you need different scheduling logic.

## Updating

```bash
# Pull latest Mix-Me customizations
git pull

# Update both upstream submodules
git submodule update --remote --merge

# Re-run the installer (recreates the venv if needed and re-installs the wrapper)
./scripts/install.sh
```
