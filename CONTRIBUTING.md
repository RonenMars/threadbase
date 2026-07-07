# Contributing to Threadbase

Thanks for your interest in contributing to Threadbase.

Threadbase is split across multiple repositories. This root repository is the umbrella project hub for documentation, roadmap, governance, and ecosystem-level coordination.

For implementation changes, please open issues or pull requests in the relevant component repository.

---

## Choose the right repository

| If your change is about... | Use this repository |
|---|---|
| Mobile app | [`threadbase-mobile`](https://github.com/RonenMars/threadbase-mobile) |
| Local runtime / streamer | [`threadbase-streamer`](https://github.com/RonenMars/threadbase-streamer) |
| Search and indexing | [`threadbase-scanner`](https://github.com/RonenMars/threadbase-scanner) |
| VS Code extension | [`threadbase-vscode`](https://github.com/RonenMars/threadbase-vscode) |
| JetBrains plugin | [`threadbase-intellij`](https://github.com/RonenMars/threadbase-intellij) |
| Desktop app | [`threadbase-electron`](https://github.com/RonenMars/threadbase-electron) |
| Menubar utility | [`threadbase-menubar`](https://github.com/RonenMars/threadbase-menubar) |
| Shared types/UI | `threadbase-core`, `threadbase-ui`, `threadbase-agent-types` |
| Ecosystem docs / roadmap / project hub | this repository |

Each component repository has its own README and roadmap. Work inside the specific component repo for implementation changes.

---

## Before opening a pull request

Please check:

- The change belongs in this umbrella repository.
- Links point to the correct component repo.
- Documentation is consistent with the current product status.
- Future or experimental functionality is clearly marked.
- Security-sensitive details are not exposed publicly.

---

## Commit and test expectations

- Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`, etc.).
- Test before pushing when your change affects behavior or build output.
- Avoid exposing secrets, API keys, pairing tokens, or private session content.

Example commit messages:

```text
docs(root): update repository map for streamer and mobile
docs(providers): clarify current Claude Code and Codex support
chore(docs): add umbrella security and trademark guidance
```

---

## Larger changes

For larger changes, please open an issue or discussion first.

Examples:

- new provider support,
- orchestration design,
- API changes,
- authentication changes,
- project-wide documentation structure,
- repository restructuring.

---

## Code of Conduct

Please follow [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

For detailed contribution guidance, see [`docs/contributing.md`](docs/contributing.md).
