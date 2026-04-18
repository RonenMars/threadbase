# Prompt: Add GitHub Actions CI

Use this prompt with Claude Code in any threadbase project that needs CI. Open a session in the target project directory and paste this prompt.

---

Add relevant GitHub Actions CI workflows for this project. Follow these constraints:

## Decisions already made (don't ask about these)

- **GitHub account:** RonenMars
- **Triggers:** push to main + pull requests to main
- **Job structure:** Separate parallel jobs (lint, build, test) — not a single matrix job
- **Test matrix:** Node projects test on Node 18, 20, 22. Go projects test on latest Go only. Kotlin/Gradle projects test on JDK 21.
- **Test depends on lint** — tests don't run if lint fails. Build runs in parallel (independent).
- **Build artifacts:** Upload dist/ (or equivalent build output) as a GitHub Actions artifact
- **Scanner dependency:** If this project depends on `@threadbase/scanner` via `file:../scanner`, clone it in CI with: `git clone https://github.com/RonenMars/threadbase-scanner.git ../scanner`
- **node-pty:** If this project uses node-pty, install build tools: `sudo apt-get update && sudo apt-get install -y python3 make g++`
- **No Co-Authored-By line** in commit messages

## What to detect from the project

Read package.json (or go.mod, build.gradle.kts, etc.) and figure out:

1. **Package manager** — npm, pnpm, yarn, go, gradle? Use whichever the project uses (check for pnpm-lock.yaml, yarn.lock, etc.)
2. **Lint command** — look at scripts in package.json. If there's a `lint` script, use it. If there's separate type-check and lint, run both. If none exists, skip the lint job.
3. **Build command** — look for `build` script. If none, skip the build job.
4. **Test command** — look for `test` script. If there are multiple (test:unit, test:integration, test:e2e), run them all. If none exists, skip the test job.
5. **Type check** — if there's a separate `typecheck` script not included in `lint`, add it to the lint job.
6. **Native dependencies** — check for node-pty, electron-builder, or other packages that need system-level build tools.
7. **Inter-project dependencies** — check for `file:../` references in dependencies.

## Reference workflow

Here's what streamer's CI looks like for reference structure (adapt commands to this project):

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm install
      - run: npm run lint

  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm install
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  test:
    name: Test (Node ${{ matrix.node-version }})
    runs-on: ubuntu-latest
    needs: lint
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm install
      - run: npm test
```

## Special cases by project type

- **Electron apps:** Don't try to run the app in CI. Lint + build + unit tests only. Skip E2E (Playwright) unless there's a headless config already set up.
- **VS Code extensions:** Build with the project's bundler (esbuild, webpack, etc.). Don't try to run VS Code in CI — unit tests only.
- **React Native / Expo:** Don't build native binaries. Run typecheck + lint + Jest tests only.
- **Go projects:** Use `go vet` and `go build` and `go test ./...`. No matrix needed — just latest Go.
- **Kotlin/Gradle (IntelliJ):** Check if CI already exists before creating. Use `./gradlew build` which typically includes compile + test.
- **Landing pages (Next.js):** Lint + build + test. Build verifies the site compiles. No deployment step.
- **Pure docs / wiki:** Skip — no CI needed for markdown-only projects.

## After writing the workflow

1. Validate the YAML is well-formed
2. Run `npm run lint` (or equivalent) locally to confirm it passes
3. Run `npm test` (or equivalent) locally to confirm tests pass
4. Show me the full diff and proposed commit message, then wait for approval before committing

## Projects that already have CI

These projects already have GitHub Actions — don't duplicate, but you can reference them:
- **streamer/** — lint, build, test (Node 18/20/22)
- **mobile/** — typecheck, unit, integration, e2e, lint
- **intellij/** — gradle build + test + plugin verification

## Projects that need CI

- **scanner/** — TypeScript lib, Biome + vitest, no native deps
- **electron/** — TypeScript + React + Electron, pnpm, has node-pty
- **vscode/** — TypeScript + React, esbuild bundler, vitest
- **landing-page-v2/** — Next.js 16, vitest, ESLint
- **cli/** — Go (deprecated, low priority)
- **landing-page-v1/** — older Next.js (likely archived, skip unless asked)
- **wiki/** — markdown only, skip
