---
name: mix-me
description: Curate music playlists from Spotify taste data, college radio charts, and Qobuz downloads; sync to Rockbox/iPod devices and Plexamp.
version: 0.1.0
author: GodSpoon
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [music, playlist, qobuz, rockbox, spotify, college-radio, plexamp]
    category: entertainment
    related_skills: []
    requires_toolsets: [terminal]
---

# Mix-Me Playlist Curator

Curate playlists from your Spotify taste profile, college-radio charts, and genre seeds; download tracks from Qobuz; and sync them to Rockbox/iPod devices or Plexamp.

## When to Use

Load this skill when the user asks for:
- A new playlist based on genres or artists ("make me a deathcore playlist")
- A built-in recipe ("run the deathcore-hyperpop recipe", "refresh college radio recommends")
- Downloading an existing draft ("download the draft and sync my iPod")
- Device sync only ("sync my innioasis")

## Prerequisites

1. Hermes Agent must be installed and running.
2. The Mix-Me Hermes tooling must be installed:
   ```bash
   cd /path/to/Mix-Me
   ./scripts/install.sh
   ```
   This creates `.venv/`, installs `hermes` in editable mode, and exposes the `mixme` wrapper at `.venv/bin/mixme`.
3. Add this skill directory to Hermes Agent's `skills.external_dirs`:
   ```bash
   hermes config set skills.external_dirs "/path/to/Mix-Me/skills"
   ```
4. Qobuz credentials must be configured via `qobuz-dl login`.
5. A `hermes.yaml` config file must exist in the Mix-Me root (copy from `config/hermes.yaml.example`).

## Quick Reference

| Intent | Command |
|---|---|
| Propose a draft | `mixme propose --genres deathcore,hyperpop --size 30 --output draft.json` |
| Propose with radio charts | `mixme propose --genres indie,electronic --radio-cache hermes-cache/radio-YYYY-MM-DD.json --output draft.json` |
| Finalize (download + M3U8) | `mixme finalize --draft draft.json` |
| Finalize + sync | `mixme finalize --draft draft.json --sync innioasis-y1` |
| Finalize + Plexamp sync | `mixme finalize --draft draft.json --plex` |
| Launch web UI | `mixme web` |
| List recipes | `mixme run --list` |
| College Radio Recommends | `mixme run college-radio --radio-cache hermes-cache/radio-YYYY-MM-DD.json` |

## Procedure

### 1. Parse intent

Determine:
- **Recipe or custom?** Built-in recipes (`college-radio`, `deathcore-hyperpop`, `hardcore-techno`, `rock-edm`, `discover-weekly`) use `mixme run <recipe>`. Arbitrary genre/size requests use `mixme propose --genres ...`.
- **Target device?** Check `hermes.yaml` for available `sync_profiles`.
- **Size?** Default is 30; override with `--size`.

### 2. Research radio charts (college-radio / discovery requests)

For `college-radio` or any request that asks for "fresh" / "radio" / "charts":

1. Refresh the radio cache:
   ```bash
   mixme refresh-radio --output hermes-cache/radio-YYYY-MM-DD.json
   ```
2. Pass `--radio-cache hermes-cache/radio-YYYY-MM-DD.json` to `propose` or `run`.

### 3. Generate a draft

Run the appropriate command:
- Custom: `mixme propose --genres <seeds> --size N --output draft.json [--radio-cache ...]`
- Recipe: `mixme run <recipe> --output "Recipe Title.json" [--radio-cache ...]`

### 4. Present the draft

Read the generated JSON and return a clean numbered tracklist:
```
1. Artist — Track (Album)
2. Artist — Track (Album)
...
```

### 5. Revise based on feedback

Accept natural-language edits: remove tracks, add more of a genre, swap a track, change size, etc. Re-run as needed and re-present.

### 6. Get explicit approval before downloading

Never run `mixme finalize` unless the user clearly approves ("looks good", "download it", "finalize", "sync it").

### 7. Finalize

Run:
```bash
mixme finalize --draft <file> [--sync <profile>] [--plex]
```

Report downloaded count, failed tracks, playlist path, and sync status.

## Handling Failures

- **Qobuz auth errors:** Tell the user to run `qobuz-dl login`.
- **Track not found on Qobuz:** Report the `(artist, track)` and ask if you should swap it out.
- **Device not mounted:** Report the configured mount path and stop.
- **Empty radio cache:** Fall back to taste-only candidates and tell the user which sources failed.

## Verification

- Draft JSON exists and contains a non-empty `tracks` array.
- M3U8 playlist exists at the configured `playlist_dir`.
- Downloaded audio files exist under the configured `music_root`.
- Sync reports OK for the requested profile(s).
