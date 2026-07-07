# Contributing Guide

Threadbase is an open-source project split across several repositories.

This umbrella repository is primarily for ecosystem-level documentation, roadmap, governance, and coordination.

For implementation changes, please contribute to the relevant component repository.

---

## Where to contribute

| Area | Repository |
|---|---|
| Mobile app | [`threadbase-mobile`](https://github.com/RonenMars/threadbase-mobile) |
| Local runtime / streamer | [`threadbase-streamer`](https://github.com/RonenMars/threadbase-streamer) |
| Search and indexing | [`threadbase-scanner`](https://github.com/RonenMars/threadbase-scanner) |
| VS Code extension | [`threadbase-vscode`](https://github.com/RonenMars/threadbase-vscode) |
| JetBrains plugin | [`threadbase-intellij`](https://github.com/RonenMars/threadbase-intellij) |
| Desktop app | [`threadbase-electron`](https://github.com/RonenMars/threadbase-electron) |
| Menubar utility | [`threadbase-menubar`](https://github.com/RonenMars/threadbase-menubar) |
| Shared types/UI | `threadbase-core`, `threadbase-ui`, `threadbase-agent-types` |
| Ecosystem docs / governance | this repository |

Each component repository has its own README and roadmap. Open issues and pull requests in the repo that owns the behavior you are changing.

---

## Good first contribution areas

- documentation fixes,
- setup instructions,
- provider metadata improvements,
- repo cross-linking,
- examples and screenshots,
- security hardening tasks,
- clarifying current vs historical docs.

---

## Contribution expectations

- use Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, etc.),
- test before pushing when behavior or build output is affected,
- avoid exposing secrets, API keys, pairing tokens, or private session content,
- keep docs consistent with current product status,
- mark future or experimental functionality clearly,
- open an issue or discussion first for larger design changes.

---

## Larger contribution areas

Please discuss direction first for:

- new provider adapters,
- orchestration changes,
- new client surfaces,
- API changes,
- authentication changes,
- package boundary changes,
- umbrella documentation structure changes.

See also [`../CONTRIBUTING.md`](../CONTRIBUTING.md).
