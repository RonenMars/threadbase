# threadbase-cli — Status & Action Items

**Last scanned:** 2026-04-12  
**Language:** Go 1.26 · Cobra 1.10  
**Visibility:** Private

---

## Status

The CLI (`cch`) is the leanest and most stable repo in the suite. All three planned phases are complete: sort/filter flags (Phase 1), JSON output (Phase 2), and multi-profile management with git branch detection (Phase 3). The build passes with standard `go build`, tests pass, and the binary is ready to use. There are no critical blockers — this is the most production-ready client.

### What's working
- `cch list` — table output with sort (`--sort`), time window (`--since` / `--after`), result cap (`--limit`), JSON mode (`--json`)
- `cch search <query>` — case-insensitive substring search across project name and preview; same sort/filter/JSON flags
- `cch show <id>` — full conversation text or JSON; prefix matching on session IDs
- `cch export <id>` — Markdown, plain text, or JSON; `--output` to file or stdout
- `cch resume <id>` — delegates to `claude --resume <sessionID>` subprocess
- `cch scan` — builds metadata cache at `~/.config/threadbase/cache.json`
- `cch profiles` — `list`, `add`, `remove`, `delete` (with confirmation), `edit` (interactive field editing), emoji support
- Git branch detection via `.git/HEAD` walk-up (handles detached HEAD)
- Single binary, no CGO, cross-platform (macOS / Linux / Windows)
- 18 test files; good coverage of parse, scan, sort, filter, export, index, render

### What's incomplete / missing
- No `--version` flag or version constant in the binary
- No `--profile <name>` flag to scope list/search/show to a single profile — all enabled profiles are always scanned
- `profiles add` does not validate that the config-dir path exists; errors only surface during the next scan
- `cch resume` does not check whether the `claude` binary is in PATH before attempting exec — the error is cryptic
- Search only covers project name and preview text; full message-content search is not supported (by design for v1, but undocumented)
- Cache invalidation is manual — `cch scan` must be run explicitly; no automatic staleness detection
- No Makefile or build scripts; cross-compile targets not defined
- Command integration tests are minimal (flags-exist checks only, no end-to-end execution tests)

---

## Action Items

### High
- [ ] Add `--profile <name>` flag to `list`, `search`, `show`, `export`, and `resume` commands so users can scope queries to a single profile
- [ ] Validate config-dir path in `profiles add` — call `os.Stat(expandHome(path))` and return a clear error immediately instead of waiting for the next scan
- [ ] Check for `claude` binary in PATH at the start of `cch resume` using `exec.LookPath("claude")` and return a helpful error message if not found
- [ ] Add a `--version` flag and embed a `Version` constant (use `-ldflags "-X main.Version=..."` in build instructions)

### Medium
- [ ] Add end-to-end command integration tests — spin up a temp directory with sample JSONL files, run `cch list`, `cch search`, `cch show`, `cch export`, and assert on output
- [ ] Implement automatic cache staleness detection — compare profile config-dir mtime against `cache.json` mtime and trigger a background re-scan when stale
- [ ] Add a `--verbose` / `-v` flag that prints parse-error counts and skipped files during `cch scan`
- [ ] Add a `Makefile` with targets: `build`, `test`, `install`, `cross-compile` (linux/amd64, darwin/arm64, windows/amd64)
- [ ] Wrap bare error returns in `cmd/export.go` line 53 and similar locations with `fmt.Errorf("context: %w", err)` for consistent error context

### Low
- [ ] Document the search-scope limitation (preview only, not full message content) in `cch search --help` output
- [ ] Add `-ldflags` version embedding to build instructions in the README
- [ ] Add a `--page` / `--offset` flag to `cch list` for large session sets (current `--limit` caps but can't paginate)
- [ ] Consider SQLite FTS5 as a future search backend for full message-content search at scale
- [ ] Add cross-compile smoke tests in CI (build for all three platforms, verify binary starts)
