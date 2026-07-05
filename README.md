# Mix-Me

Mix-Me is an interactive playlist curator that combines your Spotify taste profile, fresh college-radio charts, and genre seeds into downloadable playlists for Rockbox devices and Plexamp.

It is built on top of [Hermes Agent](https://github.com/NousResearch/hermes-agent) for orchestration and uses the [Hermes playlist tooling](https://github.com/GodSpoon/hermes) for searching Qobuz, downloading tracks, and writing M3U8 playlists.

## Features

- **Spotify-aware**: reads your saved tracks, playlists, top artists, and recently played from a local libSQL database.
- **Recipe-driven**: built-in recipes for deathcore, hyperpop, hardcore, techno, rock, EDM, and college-radio charts.
- **College Radio Recommends**: weekly scrapes of KEXP, KCRW, BBC 6 Music, NACC, WFUV, KUTX, and more.
- **Qobuz downloads**: high-resolution track downloads via `qobuz-dl-cli`.
- **Rockbox / Plexamp sync**: writes M3U8 playlists and copies them to configured devices; syncs playlists to Plex Media Server.
- **Conversational Web UI**: chat with Mix-Me to build playlists in a browser.
- **Hermes Agent skill**: install the `mix-me` skill into Hermes Agent and ask for playlists in natural language.

## Repository layout

```
Mix-Me/
├── hermes/              # submodule: playlist tooling
├── hermes-agent/        # submodule: Hermes Agent orchestrator
├── skills/mix-me/       # Hermes Agent skill for Mix-Me
├── config/              # example configuration
├── scripts/             # helper scripts
└── docs/                # documentation
```

## Quick start

```bash
git clone --recursive https://github.com/GodSpoon/Mix-Me.git
cd Mix-Me
./scripts/install.sh
```

`install.sh` creates a Python 3.13 virtual environment (falling back to `python3`), installs the Hermes tooling, exposes the `mixme` wrapper, and copies `config/hermes.yaml.example` to `hermes.yaml` if one doesn't exist.

Then:

1. Edit `hermes.yaml` with your own paths (music root, Spotify DB, Qobuz binary, sync profiles).
2. Make sure `qobuz-dl login` has been run so downloads can authenticate.
3. Add the skill to Hermes Agent:
   ```bash
   hermes config set skills.external_dirs "$PWD/skills"
   ```
   (Hermes Agent scans external skill directories; `hermes skills install <local-path>` is not supported by current Hermes Agent versions.)
4. Ask for a playlist: *"make me a deathcore playlist"*.

Or use the CLI directly:

```bash
source .venv/bin/activate
mixme propose --genres deathcore,hyperpop --size 30 --output draft.json
```

See `docs/architecture.md` for the full design.

## License

MIT
