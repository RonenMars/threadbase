# Prompt: Writing an Attractive Article About Threadbase

## App Description & Purpose

You are writing about **Threadbase** — a local-first control plane for AI coding agents.

Threadbase helps developers monitor, search, resume, and control local coding-agent sessions across:

- **Mobile app** — monitor live sessions, queue prompts, search history, and receive notifications via [threadbase.sh/betas](https://threadbase.sh/betas).
- **Desktop app (Electron)** — browse, search, and interact with sessions locally.
- **VS Code extension** — surface coding-agent history inside the editor.
- **IntelliJ plugin** — equivalent integration for JetBrains IDEs.
- **Streamer + scanner stack** — local runtime and history indexing through `threadbase-streamer` and `threadbase-scanner`.

**Core purpose:** AI coding agents store conversation history locally, but the workflow is still fragmented across terminals, provider-specific tools, and raw files. Threadbase provides a local-first layer for search, control, and supervision — currently focused on **Claude Code and Codex**.

---

## The Need It Fulfills

Developers using AI coding agents frequently face these pain points:

- **Losing the reasoning, not just the solution.** An agent may have explained a multi-step architecture decision, but if you didn't copy it down, it is buried in raw history files.
- **No easy way to reference past tool invocations.** Commands, diffs, and file reads disappear unless you scroll through old terminal sessions.
- **No project context on old sessions.** It is hard to know which repo a past session belongs to or filter history by current work.
- **No easy way to search or filter history** by project, keyword, date, or provider.
- **Having to dig through raw JSON/log files** to recover prior context.
- **Mobile supervision is awkward** when sessions run on a local machine.

Threadbase addresses this by turning local agent history and active sessions into a **navigable, developer-friendly operational surface**.

---

## Key Stats & Specifics

Article writers can cite these concrete facts:

- **Current provider focus:** Claude Code and Codex.
- **Local-first model:** sessions and history stay on your machine unless you explicitly configure remote access.
- **Mobile beta:** available at [threadbase.sh/betas](https://threadbase.sh/betas).
- **Streamer workflow:** pair mobile clients with `tb-streamer pair` after starting `tb-streamer start`.
- **Export formats supported:** Markdown, plain text, JSON on several clients.
- **Search/indexing:** local history indexing and search through `threadbase-scanner`.
- **Client surfaces:** mobile, desktop, VS Code, IntelliJ, and menubar utilities.
- **Tool result cards rendered on several clients:** Edit diffs, Bash output, Read/Write/Glob/Grep, and generic fallback cards.

Keep future capabilities (cloud sync, team dashboards, broad provider support) clearly labeled as roadmap unless implemented.

---

## What Makes This Different

Why not just open raw history files directly?

- **Raw JSONL/log files are unreadable at a glance.** Each line is dense structured data with nested content, tool calls, and metadata.
- **Local-first control.** Threadbase is designed around user-owned machines and explicit streamer pairing rather than requiring hosted session storage.
- **Cross-surface workflow.** The same local sessions can be monitored from mobile while work continues on desktop/IDE surfaces.
- **Tool result cards.** Several clients render tool output as readable cards (diffs, terminal output, file operations) instead of opaque JSON blobs.
- **Provider-aware direction.** Threadbase currently supports Claude Code and Codex while keeping architecture open to additional providers over time.
- **Searchable history + live control.** History indexing and active session control are complementary, not separate products.

---

## Pros

- **Multi-surface** — mobile, desktop, and IDE clients over the same local stack.
- **No cloud dependency by default** — local history and local execution.
- **Productivity boost** — quickly recover prompts, patterns, and prior decisions.
- **Context recovery** — resume old threads without re-explaining the entire problem.
- **Searchability** — find relevant past exchanges without manual file digging.
- **Learning tool** — review prompting patterns over time.
- **Export** — save conversations to Markdown, plain text, or JSON.

## Cons / Honest Limitations

- Most useful when you already run supported coding agents locally.
- Provider support varies by client and repository.
- Some clients are still evolving and feature parity is not guaranteed.
- Mobile beta distribution and onboarding may change as the product matures.
- Optional future hosted/team features should not be presented as current unless shipped.

---

## Article Writing Guide

### Platform Best Practices

**Medium:** Favor storytelling and narrative flow. Lead with a relatable developer frustration. Use subheadings sparingly. Aim for 800–1,500 words. Embed code snippets and screenshots. End with a personal reflection or call-to-action.

**dev.to:** More technical and community-oriented. Use tags like `#opensource`, `#devtools`, `#productivity`, `#claudecode`, and `#ai`. Shorter paragraphs, more bullet points, and GIFs/screenshots are welcome. A "TL;DR" at the top performs well. 1,000–2,000 words is the sweet spot.

---

### Recommended Article Structure

> **Important framing note:** Focus on Threadbase as a product concept — local-first control, search, and supervision for AI coding agents. Mention client surfaces briefly (mobile, desktop, IDE) as accessibility, not as a platform-by-platform spec sheet.

1. **Hook (opening paragraph):** Start with a scenario developers recognize — losing a prior agent explanation, needing to supervise a long-running local session from mobile, or failing to find an old architecture decision in raw history files.

2. **The problem:** Explain why raw local agent history and fragmented terminals are painful. Keep it factual and empathetic.

3. **Introducing Threadbase:** Present Threadbase as a local-first control plane for AI coding agents. Mention Claude Code and Codex support and that mobile beta is available.

4. **Key features walkthrough:** Use screenshots or a short GIF. Show search, session monitoring, and control/resume workflows where possible.

5. **Real-world use case:** Write a short scenario — e.g., recovering a prior refactor plan from history, or monitoring a local session from mobile while away from desk.

6. **Honest pros & cons:** Include at least two limitations to build credibility.

7. **Installation / getting started:** Link to [threadbase.sh](https://threadbase.sh), [threadbase.sh/betas](https://threadbase.sh/betas), and relevant component repos. Keep setup concise.

8. **Call to action / closing:** Invite feedback, a GitHub star, or comments on how readers use local agent workflows.

---

### Tone & Style Tips

- Write in **first person** when sharing personal experience.
- Avoid marketing hype ("revolutionary", "game-changing").
- Use **concrete numbers** when possible.
- **Screenshots are strongly recommended** — main UI, search, and at least one control/monitoring workflow.
- Keep paragraphs short on dev.to; slightly longer on Medium.
- Use a **descriptive, specific title** — e.g., *"I built a local control plane for AI coding agents — here's why it changed my workflow"*.

---

### SEO / Discoverability Tips (especially for dev.to)

- Include terms developers search for: `Threadbase`, `AI coding agents`, `Claude Code`, `Codex`, `local-first developer tools`, `AI coding history`.
- The title, first paragraph, and at least one subheading should naturally contain the primary keyword phrase.
- A strong meta description should summarize the problem and local-first solution in one sentence.

---

## Distribution links

- Website: [threadbase.sh](https://threadbase.sh)
- Mobile beta: [threadbase.sh/betas](https://threadbase.sh/betas)
- Privacy policy: [threadbase.sh/privacy](https://threadbase.sh/privacy)
