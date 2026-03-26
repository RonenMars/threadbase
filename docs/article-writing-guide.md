# Prompt: Writing an Attractive Article About the Claude Code History Apps

## App Description & Purpose

You are writing about a suite of **Claude Code History** developer tools available across three platforms:

- **Electron desktop app** — a standalone cross-platform GUI for browsing, searching, and managing Claude Code session history outside of the terminal. The most feature-rich implementation, including an embedded Claude Code chat terminal.
- **VS Code Extension** — an integrated panel inside Visual Studio Code that surfaces Claude Code conversation history directly within the editor, keeping developers in their flow.
- **IntelliJ Plugin** — equivalent integration for the IntelliJ IDEA ecosystem (and compatible JetBrains IDEs), bringing the same history browsing capability to Java, Kotlin, and backend-focused developers. Currently in progress.

**Core purpose:** Claude Code stores conversation history locally as JSONL files, but there's no first-class UI for exploring it. These tools bridge that gap — giving developers a structured, searchable, and readable interface to revisit past AI-assisted coding sessions, recover context, and learn from prior interactions.

---

## The Need It Fulfills

Claude Code users frequently face these pain points:

- **Losing the reasoning, not just the solution.** Claude might have explained a three-step architecture decision, but if you didn't copy it down, it's buried somewhere in a raw JSONL file.
- **No way to reference past tool invocations.** Claude ran a bash command, produced a diff, or read a file — and that output is gone unless you scroll back through an old terminal session.
- **No project context on old sessions.** There's no way to know which project a past session belongs to, or to filter history by the repo you're working in today.
- **No easy way to search or filter history** by project, keyword, date, or file.
- **Having to dig through raw JSON/log files** to recover prior context — `~/.claude/projects/` is not human-friendly.
- **Switching between terminal and other tools breaks flow** for IDE-native developers.

The Claude Code History apps solve this by turning raw session data into a **navigable, developer-friendly knowledge base** of everything Claude has helped them build.

---

## Key Stats & Specifics

Article writers can cite these concrete facts:

- **Export formats supported:** Markdown, plain text, JSON — available on all three platforms.
- **Electron app:** Supports up to N concurrent embedded Claude Code sessions (default: 3), each running in a full xterm.js terminal via node-pty, tracked by UUID.
- **VS Code extension:** Uses FlexSearch for full-text search, with an LRU cache of 5 conversation entries to avoid re-parsing large JSONL files on repeat visits.
- **IntelliJ plugin:** Uses Apache Lucene 9.x (in-memory, JVM-native) for full-text search with multi-field and prefix matching.
- **Keyboard shortcuts:** `Cmd+F` to focus search in the Electron app; `Ctrl+Shift+H` to focus the Claude History search field from anywhere in the IntelliJ IDE.
- **Platforms:** All three run on macOS, Windows, and Linux. The IntelliJ plugin targets WebStorm and IntelliJ IDEA 2025.3+.
- **Multi-profile support:** All platforms support scanning across multiple Claude Code config directories (e.g., a personal `~/.claude` and a work `~/.claude-work`).
- **Tool result cards rendered:** `Edit` (unified diff view), `Bash` (terminal output), `Read`, `Write`, `Glob`, `Grep`, and a generic fallback card for other tool types.

---

## What Makes This Different

Why not just open the JSONL files directly, or use Claude.ai's web history?

- **Claude.ai web history is a different product.** Claude Code conversations live locally on disk and are never synced to Claude.ai's web interface. They're invisible there.
- **Raw JSONL files are unreadable at a glance.** Each line is a dense JSON blob with nested content arrays, tool call arguments, token counts, and metadata. Parsing them by hand to find one conversation is genuinely painful.
- **Tool result cards.** This is the key differentiator from any naive viewer. When Claude runs `Edit`, the app renders a proper unified diff — red deletions, green additions, filename header. When Claude runs `Bash`, you see the terminal output in a styled card. These aren't just text — they're rendered the same way a code review tool would show them.
- **Embedded chat terminal (Electron).** You can resume or start a Claude Code session directly inside the history browser — you don't have to leave the window, find the right directory, and type `claude --resume <session-id>` yourself.
- **Project grouping.** Conversations are grouped by the project directory they belong to, so you can immediately see all sessions related to a given repo, not just a flat chronological list.
- **Multi-profile support.** Developers with separate personal and work Claude Code configurations can scan both in one view.

---

## Pros

- **Multi-platform** — meets developers where they already work (desktop, VSCode, IntelliJ).
- **No cloud dependency** — all history is local; privacy is preserved.
- **Productivity boost** — quickly reuse prompts, patterns, and solutions from past sessions.
- **Context recovery** — resume old threads without re-explaining the entire problem to Claude.
- **Searchability** — find relevant past exchanges without scrolling through terminal output.
- **Learning tool** — review how you prompted Claude over time and refine your technique.
- **Export** — save any conversation to Markdown, plain text, or JSON for notes, docs, or sharing.

## Cons / Honest Limitations

- Only useful to active Claude Code users — no value without existing history.
- History quality depends on the user's own prompting habits.
- IDE plugins add a dependency that must be maintained across IDE version updates.
- The Electron app is an extra app to install for users who prefer staying IDE-native.
- The IntelliJ plugin is still in progress — some features available in the Electron app (like the embedded chat terminal and git worktrees panel) are not yet present.

---

## Article Writing Guide

### Platform Best Practices

**Medium:** Favor storytelling and narrative flow. Lead with a relatable developer frustration. Use subheadings sparingly. Aim for 800–1,500 words. Embed code snippets and screenshots. End with a personal reflection or call-to-action.

**dev.to:** More technical and community-oriented. Use the `#opensource`, `#claudecode`, `#devtools`, `#productivity` tags. Shorter paragraphs, more bullet points, and GIFs/screenshots are welcome. A "TL;DR" at the top performs well. 1,000–2,000 words is the sweet spot.

---

### Recommended Article Structure

> **Important framing note:** The article should focus on the **concept and value of the tool as a whole** — what it does, why it exists, and who it's for. The fact that it's available across multiple platforms (Electron, VSCode, IntelliJ) should be mentioned briefly as a single point about accessibility, not explored per-platform. The article is about the *experience and purpose*, not the implementation differences between platforms.

1. **Hook (opening paragraph):** Start with a scenario every Claude Code user recognizes — "You remember Claude gave you that perfect regex last Tuesday... but where did it go?" Make the reader feel the pain before offering the solution.

2. **The problem:** Briefly explain the limitation of Claude Code's raw history storage. Keep it factual and empathetic, not whiny.

3. **Introducing the app:** Present Claude Code History as a single, unified tool concept. Mention in one sentence that it's available across Electron, VSCode, and IntelliJ so readers know it fits their environment — then move on. The article is not a platform comparison.

4. **Key features walkthrough:** Use screenshots or a short GIF of the core UI. Show the search interface, the session browser, and the history timeline. "Show, don't tell." Keep the visuals platform-agnostic where possible.

5. **Real-world use case:** Write a short scenario — e.g., "I was refactoring a service three weeks later and needed to find the architecture Claude and I had worked out. I opened the history panel, searched 'service layer', and had it in 10 seconds."

6. **Honest pros & cons:** Readers trust articles that acknowledge limitations. Include at least 2 cons — this builds credibility.

7. **Installation / getting started:** A brief section pointing readers to the platform that suits them, with a link to the repo or install instructions. One or two lines per platform max — the goal is to get them started, not to document each one.

8. **Call to action / closing:** Invite feedback, a GitHub star, or a comment sharing how they use it. End with energy and openness.

---

### Tone & Style Tips

- Write in **first person** — share your own experience building or using the tool.
- Avoid marketing language ("revolutionary", "game-changing"). Developers distrust hype.
- Use **concrete numbers** when possible: "Saved me ~15 minutes of digging per day."
- **Screenshots are mandatory** — at minimum: the main UI, the search feature, and the IDE integration panel.
- Keep paragraphs to 2–4 sentences max on dev.to; slightly longer on Medium.
- Use a **descriptive, specific title** — e.g., *"I built a UI for Claude Code's hidden history — here's why it changed how I code"* rather than *"Introducing Claude Code History App"*.

---

### SEO / Discoverability Tips (especially for dev.to)

- Include terms developers actually search: `Claude Code`, `AI coding history`, `AI coding assistant`, `developer productivity tools 2025`.
- The article title, first paragraph, and at least one subheading should naturally contain the primary keyword (`Claude Code history`).
- A strong meta description (for Medium's subtitle or dev.to's excerpt field) should summarize the problem and solution in one sentence.
