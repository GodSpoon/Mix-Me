# Mix-Me Usage Guide

This guide covers installing, configuring, and running Mix-Me both as a command-line tool and as a Hermes Agent skill.

## Install

```bash
git clone --recursive https://github.com/GodSpoon/Mix-Me.git
cd Mix-Me
./scripts/install.sh
```

`install.sh` does the following:

- Initializes/updates git submodules (`hermes/`, `hermes-agent/`).
- Creates a Python 3.13 virtual environment at `.venv/` (falls back to `python3` if 3.13 is unavailable).
- Installs the Hermes playlist tooling in editable mode.
- Exposes the `mixme` wrapper at `.venv/bin/mixme`.
- Copies `config/hermes.yaml.example` to `hermes.yaml` if it does not exist.

Activate the environment for manual CLI use:

```bash
source .venv/bin/activate
mixme --help
```

## Configure `hermes.yaml`

Edit the generated `hermes.yaml` in the repo root. The key fields are:

```yaml
spotify_db: /path/to/your/spotify-data.db          # libSQL/SQLite Spotify export
download_cache: /path/to/downloads.sqlite          # SHA-256 verified download cache
music_root: /path/to/your/music/library            # where audio files live
playlist_dir: /path/to/your/music/library/Playlists
qobuz_dl: /path/to/qobuz-dl                        # Qobuz-DL CLI v2 binary
cache_dir: /path/to/hermes-cache                   # radio cache, logs, etc.

sync_profiles:
  ipod-classic:
    command: 'python3 /path/to/ipod-sync.py /path/to/music /Volumes/iPod/Music --format mp3 --bitrate 192k'
  plex-local:
    command: 'rsync -av /path/to/music/Playlists/ /path/to/plex/playlists/'

radio_sources:
  - name: kexp
    query_template: 'site:kexp.org "song of the day"'
  # ... (see config/hermes.yaml.example for the full default set)

# Optional Plex Media Server sync
# plex:
#   url: http://localhost:32400
#   token: ${PLEX_TOKEN}
#   music_library: Music

recipes:
  college-radio:
    title: "College Radio Recommends"
    description: "Fresh picks from college and indie radio stations."
    genre_seeds: [indie, rock, electronic, alternative]
    radio_source_names: [kexp, kcrw, bbc6, nacc, wfuv, kutx]
  # ... (built-in recipes are already in the example)
```

### Spotify database

`spotify_db` should point to a libSQL/SQLite database containing your Spotify data. The Mix-Me tooling reads:

- saved tracks
- top artists
- followed artists
- recently played
- playlists

If you do not have one yet, export your Spotify library to a libSQL-compatible database and set the path.

### Qobuz authentication

Run Qobuz-DL's login flow **outside** Mix-Me so the token is stored in Qobuz-DL's config:

```bash
qobuz-dl login
```

Then point `qobuz_dl:` in `hermes.yaml` to the binary.

## CLI commands

All commands are available as `mixme <command>` once the venv is activated, or as `.venv/bin/mixme <command>` from the repo root.

### `propose` — generate a draft

Create a JSON draft from genre seeds (and optionally a radio cache):

```bash
mixme propose --genres deathcore,hyperpop --size 30 --output draft.json

# include radio charts
mixme propose --genres indie,electronic --radio-cache hermes-cache/radio-2026-07-05.json --size 30 --output draft.json
```

### `run` — use a recipe

List recipes:

```bash
mixme run --list
```

Run one:

```bash
mixme run college-radio --radio-cache hermes-cache/radio-2026-07-05.json --output "College Radio Recommends.json"
mixme run deathcore-hyperpop --size 20 --output "Deathcore Hyperpop.json"
```

### `finalize` — download and write M3U8

```bash
mixme finalize --draft draft.json
```

Options:

- `--sync <profile>` — run a sync profile (can be repeated).
- `--plex` — sync the playlist to the configured Plex Media Server.
- `--no-download` — write the M3U8 without downloading.
- `--auto-swap` — automatically replace failed tracks with the best Qobuz alternative.

Example:

```bash
mixme finalize --draft draft.json --sync ipod-classic --plex
```

### `web` — conversational web UI

Launch a local Flask UI for building playlists in a browser:

```bash
mixme web --host 127.0.0.1 --port 5000
```

Then open `http://127.0.0.1:5000`.

### Refreshing the radio cache

```bash
DATE=$(date +%F)
.venv/bin/python hermes/scripts/refresh_radio_cache.py --config hermes.yaml --output hermes-cache/radio-$DATE.json
```

This uses the `radio_sources:` defined in `hermes.yaml`. Add `--browser` if a source needs a JavaScript-rendered page (requires Playwright).

There is also a convenience script for the weekly "College Radio Recommends" flow:

```bash
./scripts/weekly_college_radio.sh
```

It refreshes the cache, builds the college-radio draft, finalizes it (download + M3U8), and writes everything under `hermes-cache/`.

## Recipes

Recipes are YAML definitions under `recipes:` in `hermes.yaml`. A minimal recipe:

```yaml
recipes:
  deep-techno:
    title: "Deep Techno"
    description: "Hypnotic, minimal techno."
    genre_seeds: [deep techno, minimal techno, dub techno]
```

Recipes can also use radio charts:

```yaml
recipes:
  college-radio:
    title: "College Radio Recommends"
    genre_seeds: [indie, rock, electronic, alternative]
    radio_source_names: [kexp, kcrw, bbc6, nacc, wfuv, kutx]
```

Add custom recipes to `hermes.yaml` (or merge `config/recipes.yaml.example`) and they appear in `mixme run --list`.

## Hermes Agent skill

After install, register the skill with Hermes Agent by pointing `skills.external_dirs` at the Mix-Me `skills/` directory:

```bash
hermes config set skills.external_dirs "$PWD/skills"
```

Then start chatting:

```bash
hermes
```

Example prompts:

- "make me a deathcore playlist with 20 tracks"
- "run the college-radio recipe"
- "refresh the radio cache and build an indie playlist"
- "finalize that draft and sync it to my iPod"

The skill will call `mixme` commands on your behalf. It asks for approval before running `finalize` (which downloads and syncs).

## Downloads and the download cache

`finalize` uses Qobuz-DL CLI v2 to download tracks into `music_root`. A SHA-256 verified download cache at `download_cache:` prevents re-downloading files you already have.

If a track cannot be found, Mix-Me reports the failure and, when `--auto-swap` is not used, may suggest alternatives found on Qobuz.

## Sync profiles

Sync profiles are arbitrary shell commands. They receive no arguments; you hard-code source/destination paths in `hermes.yaml`. The command's exit code determines success.

Common patterns:

- `rsync` to a mounted device.
- A custom Python script (e.g. `ipod-sync.py`).
- `cp` to a Plex playlist directory.

## Plexamp / Plex Media Server

Add a `plex:` section to `hermes.yaml`:

```yaml
plex:
  url: http://localhost:32400
  token: ${PLEX_TOKEN}
  music_library: Music
```

Then pass `--plex` to `finalize`:

```bash
mixme finalize --draft draft.json --plex
```

The Plex client searches the library for each track and creates/updates a playlist named after the draft.

## Typical workflows

### Custom genre playlist

```bash
mixme propose --genres deathcore,metalcore --size 25 --output deathcore.json
# review deathcore.json
mixme finalize --draft deathcore.json --auto-swap
```

### College Radio Recommends (weekly)

```bash
./scripts/weekly_college_radio.sh
```

### Radio-assisted discovery

```bash
DATE=$(date +%F)
mixme refresh-radio --output hermes-cache/radio-$DATE.json
mixme propose --genres indie,electronic,rock --radio-cache hermes-cache/radio-$DATE.json --size 30 --output radio-mix.json
mixme finalize --draft radio-mix.json --sync plex-local
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `externally-managed-environment` during install | Run `./scripts/install.sh`; it installs into a venv. |
| `ModuleNotFoundError: No module named 'libsql_experimental'` | Make sure you are using `.venv/bin/mixme` or have activated `.venv/`. Do not run the wrapper with a different Python. |
| `propose` returns 0 tracks | You need a populated `spotify_db`, a radio cache, or use a recipe that discovers on Qobuz. |
| Qobuz auth errors | Run `qobuz-dl login` and verify `qobuz_dl:` in `hermes.yaml`. |
| Skill not loaded by Hermes Agent | Use `hermes config set skills.external_dirs "/path/to/Mix-Me/skills"`; local paths are not accepted by `hermes skills install`. |
| Track not found on Qobuz | Re-run `finalize` with `--auto-swap`, or edit the draft JSON manually. |
| Device not mounted | Check the sync profile command and ensure the destination volume/path is available. |

## Updating

```bash
git pull
git submodule update --remote --merge
./scripts/install.sh
```
