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

Then, either:

- **Hermes Agent**: `hermes skills install skills/mix-me` and ask *"make me a deathcore playlist"*.
- **CLI directly**: `cd hermes && pip install -e . && cd .. && ./scripts/weekly_college_radio.sh`

See `docs/architecture.md` for the full design.

## License

MIT
