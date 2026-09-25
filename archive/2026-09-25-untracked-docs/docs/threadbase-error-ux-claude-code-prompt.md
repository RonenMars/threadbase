# Claude Code Prompt — Threadbase Error UX: Severity-Aware Recovery System

You are working on the Threadbase mobile application.

I want you to redesign and implement the application’s error UX around a **severity-aware recovery system** that combines two patterns:

1. **Option 1 — Dominant recovery UI**
   - A visually prominent recovery surface, usually a bottom sheet or major centered error state.
   - Used for errors that materially affect the session or make an important part of the screen unavailable.

2. **Option 2 — Contextual inline errors**
   - Errors shown directly where the failed content or feature normally appears.
   - Used when the failure is local and the rest of the screen remains meaningfully usable.

The key design decision is:

> **Option 1 is the primary architecture. Option 2 is a secondary presentation mechanism for local failures and for persistent contextual reminders after a major error has been dismissed.**

Do not treat the compact alert bar as the primary error surface for important failures. For major or critical errors, the user should first see a dominant recovery UI. The compact alert bar should generally be the minimized / persistent state after the main error UI has already been shown.

---

# Product Context

Threadbase is a developer-facing mobile application for viewing and controlling AI coding sessions.

A single session screen may depend on several independently loaded resources, for example:

- connection to the host machine
- session metadata
- messages
- terminal / shell state
- live control
- agent status
- attachments
- streamer / backend connectivity
- authentication / authorization
- other session-related APIs

Some failures are local.

Others effectively mean that the session is partially or fully unusable.

The UI must communicate that difference clearly.

For example:

```text
Can't reach Ronens-MacBook
```

is significantly more important than:

```text
Session metadata failed to load
```

The former should not initially appear as only a small alert bar.

---

# Core UX Model

All user-facing errors should be classified by presentation severity.

Use three primary levels:

```ts
type ErrorPresentation =
  | 'inline'
  | 'recovery-sheet'
  | 'blocking';
```

Conceptually:

```text
                     ERROR
                       │
             ┌─────────┴─────────┐
             │                   │
          Local               Global
             │                   │
             ▼             ┌─────┴─────┐
       Inline error        │           │
                         Major      Critical
                           │           │
                           ▼           ▼
                    Recovery sheet   Blocking
                           │           UI
                           │
                      dismissed?
                           │
                           ▼
                   Persistent banner
                           +
                     inline marker
```

---

# Where to Use Option 1

## 1. Major Errors → Dominant Recovery Sheet

Use **Option 1 / recovery-sheet** when:

- an important session capability fails
- several related requests fail at once
- the user needs to understand that the current screen is degraded
- the screen is still partially usable
- retrying may recover the state
- dismissing the error is reasonable

Examples:

- messages cannot be loaded
- session details cannot be loaded
- terminal metadata cannot be loaded
- live-control state is unavailable
- multiple session APIs fail together
- partial backend failure
- several independent resources fail during initial screen load

### Initial presentation

The recovery UI should open automatically.

Example:

```text
╭─────────────────────────────────────╮
│ ⚠ Some session features unavailable │
│                                     │
│ 3 requests failed                   │
│                                     │
│ ▾ Machine connection                │
│   Can't reach Ronens-MacBook        │
│                            [Retry]  │
│                                     │
│ ▸ Messages                          │
│   Messages couldn't load     [Retry]│
│                                     │
│ ▸ Session details                   │
│   Details couldn't load      [Retry]│
│                                     │
│             [ Retry all ]           │
╰─────────────────────────────────────╯
```

Each error should support:

1. user-friendly title
2. optional user-friendly explanation
3. raw error code
4. raw error message
5. individual Retry
6. Copy for technical fields
7. independent retry state

If there is more than one retryable error:

```text
Retry all
```

must be available.

### After dismissal

If the user closes the recovery sheet, the failure should remain visible in a compact persistent form.

Example:

```text
⚠ 2 requests couldn't be completed
                         Retry all · Details
```

This compact alert is a **persistent reminder**, not the primary notification mechanism.

The failed local sections may also show contextual inline states.

---

## 2. Critical Errors → Blocking Error State

Use **Option 1 / blocking** when the screen is effectively unusable.

Examples:

- host machine unreachable and the session cannot function without it
- session disconnected with no usable local state
- authentication failure
- authorization failure
- session no longer exists
- session was deleted / invalidated
- unrecoverable streamer connection failure
- required configuration is missing
- the user cannot meaningfully continue on the current screen

Example:

```text
        ⚠

Can't reach Ronens-MacBook

This session can't continue until
the connection is restored.

        [ Retry ]

Technical details ›

        [ Go back ]
```

Important behavior:

- do **not** use a normal dismiss `X` if dismissing would reveal a screen that cannot actually function
- prefer:
  - Retry
  - Go back
  - Reconnect
  - Re-authenticate
  - another explicit recovery/navigation action
- technical details should remain accessible but visually secondary

---

# Where to Use Option 2

Use **Option 2 / contextual inline errors** when the failure is local and the rest of the screen remains meaningfully usable.

Examples:

- session metadata subsection failed
- avatar failed
- auxiliary statistics failed
- attachments failed
- one optional widget failed
- one informational panel failed
- a non-critical API request failed
- a single control has stale data but the rest of the session is still functional

Example:

```text
Session details

⚠ Session details couldn't load
We couldn't retrieve the latest session information.

[Retry]   [Technical info]
```

Technical details may expand inline:

```text
Technical details

Error code
503 SERVICE_UNAVAILABLE              [Copy]

Raw error
The server is busy; retrying shortly [Copy]
```

The retry control should remain close to the failed content.

---

# Hybrid Behavior

The two patterns should work together.

For a major error:

```text
Major error occurs
        ↓
Dominant recovery sheet opens automatically
        ↓
User dismisses it
        ↓
Persistent global alert remains
        +
affected section shows inline failure state
```

Example:

```text
Waiting   Claude   Live control   Terminal

⚠ 2 issues                         Details
─────────────────────────────────────────

Session details

⚠ Session details unavailable
                             Retry

Messages

[existing cached messages remain visible]
```

This provides:

- strong initial communication
- non-blocking continuation where appropriate
- contextual recovery
- persistent awareness
- centralized diagnostics

---

# Required Error Data Model

Inspect the existing repository first and adapt this concept to the current architecture.

Do not introduce a parallel error system if an existing centralized mechanism can be evolved.

A possible conceptual model:

```ts
type ErrorPresentation =
  | 'inline'
  | 'recovery-sheet'
  | 'blocking';

type AppErrorStatus =
  | 'failed'
  | 'retrying'
  | 'resolved';

type AppError = {
  id: string;

  // User-facing
  title: string;
  description?: string;

  // Technical
  code?: string;
  rawMessage?: string;

  // UX classification
  presentation: ErrorPresentation;

  // Recovery
  retryable: boolean;
  retry?: () => Promise<void>;

  // State
  status: AppErrorStatus;

  // Optional context
  source?: string;
  resource?: string;
};
```

This is illustrative only.

Use the repository’s existing conventions where possible.

---

# Error Mapping Layer

The UI should not infer friendly copy directly from arbitrary fetch / Axios / WebSocket / backend errors.

Create or reuse a normalization layer that maps raw errors into user-facing error objects.

Example mappings:

```text
ECONNREFUSED
→ "Can't connect to the Threadbase server"

401
→ "Your session has expired"

403
→ "You don't have permission to access this"

404
→ "This session could no longer be found"

408 / timeout
→ "The server took too long to respond"

429
→ "Too many requests"

500–599
→ "The server couldn't complete the request"

offline
→ "You're offline"
```

Preserve the original raw code and raw message for technical details.

Do not lose diagnostic information.

---

# Retry UX

Each error must own its retry state independently.

Use states like:

```text
Idle      → Retry
Retrying  → Retrying…
Resolved  → remove / resolve error
Failed    → Retry
```

If retry succeeds:

- remove or resolve the error
- update any aggregate error count
- close the dominant recovery UI automatically when no unresolved errors remain
- optionally show a short success state before dismissing

Example:

```text
2 requests failed
↓
Retry Messages
↓
1 request failed
```

When all recover:

```text
✓ Everything loaded
```

Then dismiss automatically after a brief delay.

---

# Retry All

Show `Retry all` only when there are at least two retryable unresolved errors.

Behavior:

- run retries safely
- prevent duplicate concurrent retry calls for the same error
- show aggregate retry progress
- allow individual errors to resolve independently
- if some succeed and some fail, keep only the unresolved failures

Example:

```text
[ Retrying 2 requests… ]
```

When complete:

```text
1 request still failed
```

---

# Automatic Retry Before Escalation

For transient network/server failures, automatically retry before showing a dominant user-facing error when appropriate.

Good candidates:

- 429
- 502
- 503
- 504
- timeout
- temporary network interruption
- WebSocket reconnect
- transient streamer connectivity failure

Example:

```text
Attempt 1 failed
→ retry after ~500 ms

Attempt 2 failed
→ retry after ~1.5 s

Attempt 3 failed
→ escalate to user-facing error
```

During automatic recovery:

```text
Reconnecting…
```

is preferable to immediately showing:

```text
The server is busy; retrying shortly
```

Do not blindly auto-retry:

- 401
- 403
- most 404s
- validation errors
- invalid configuration
- other deterministic failures that retrying cannot fix

Reuse existing retry/backoff infrastructure if present.

---

# Visual Hierarchy

Do not use red as the primary treatment for every button and border.

Reserve error color for:

- warning/error icon
- status indicator
- small accent
- critical state emphasis

`Retry` is a recovery action, not a destructive action.

Use the app’s normal primary-action styling for Retry / Retry all.

Technical information should be visually secondary:

- smaller text
- monospace where appropriate
- neutral color
- hidden behind `Technical details` when practical
- Copy controls for raw code and raw message

---

# Accessibility Requirements

Ensure:

- screen reader labels for error state, retry buttons, expand/collapse controls, and Copy buttons
- focus moves appropriately when a blocking or recovery-sheet error opens
- focus returns sensibly after dismissal
- retry state is announced
- success / resolution is announced
- error state is not communicated by color alone
- touch targets meet mobile accessibility guidelines
- expanded/collapsed state is accessible

---

# Practical Implementation Plan

Before changing code:

## Step 1 — Inspect the existing architecture

Read the relevant Threadbase mobile codebase and identify:

- current error components
- current alert/banner components
- modal / sheet infrastructure
- current request hooks / API layer
- query library, if any
- retry/backoff behavior
- global state management
- session screen structure
- WebSocket / streamer reconnect logic
- existing error normalization
- design-system components
- accessibility conventions

Do not start implementation until you understand the existing flow.

---

## Step 2 — Inventory current error paths

Find all error presentations on the session screen and categorize them.

Produce a short table before implementation:

| Existing error | Source | Current UI | Proposed severity | Proposed UI |
|---|---|---|---|---|
| Host unreachable | connection | banner | critical | blocking |
| Messages fetch | API | modal | major | recovery-sheet + inline |
| Session metadata | API | modal | local/major | inline or sheet depending on impact |
| ... | ... | ... | ... | ... |

Use actual repository behavior, not assumptions.

---

## Step 3 — Define a central severity / presentation policy

Add or adapt one central place responsible for deciding:

```text
raw error
→ normalized error
→ severity/presentation
→ UI
```

Avoid scattered logic such as:

```ts
if (error) showModal()
```

inside many components.

Prefer a reusable policy.

---

## Step 4 — Implement / refactor shared error primitives

Where appropriate, create reusable components such as:

```text
ErrorInlineState
ErrorRecoverySheet
BlockingErrorState
ErrorTechnicalDetails
ErrorSummaryBanner
RetryAllButton
```

Names should follow the repository’s conventions.

Do not over-componentize if existing shared components already cover these responsibilities.

---

## Step 5 — Implement Option 1

Implement the dominant recovery surface for major errors.

Requirements:

- automatically opens for newly surfaced major errors
- supports one or many errors
- accordion/list items
- each item:
  - friendly title
  - friendly description
  - technical details
  - code
  - raw message
  - copy
  - retry
- `Retry all` for multiple retryable errors
- independent retry progress
- successful errors disappear
- sheet closes when all errors resolve
- user can dismiss only if the underlying screen remains usable

---

## Step 6 — Implement critical blocking state

For truly critical failures:

- show a major centered or bottom blocking state
- no ordinary close button if the user cannot meaningfully continue
- Retry
- Go back / appropriate navigation
- technical details
- clear explanation of impact

Use existing navigation patterns.

---

## Step 7 — Implement Option 2

For local errors:

- render the error in the affected section
- preserve unaffected content
- put Retry near the failed content
- optionally show Technical details inline
- avoid global interruption

---

## Step 8 — Add hybrid persistence

When a major recovery sheet is dismissed:

- keep a compact global issue indicator/banner
- keep local inline failure states where relevant
- allow reopening the recovery sheet via `Details`

Example:

```text
⚠ 2 issues                         Details
```

---

## Step 9 — Integrate automatic retry

Reuse existing retry/backoff logic where possible.

For retryable transient errors:

```text
raw failure
→ automatic recovery attempts
→ only escalate after retries fail
```

The UI should show calm transient states like:

```text
Reconnecting…
```

instead of prematurely showing technical error details.

---

## Step 10 — Tests

Add or update tests for at least:

### Classification

- local error → inline
- major error → recovery sheet
- critical error → blocking state

### Single error

- Retry visible
- technical details available
- Retry all absent

### Multiple errors

- all errors listed
- individual Retry works
- Retry all visible

### Retry success

- resolved error removed
- count updates
- recovery sheet closes when all resolve

### Retry partial success

- resolved errors disappear
- remaining errors remain visible

### Dismissal

- major sheet dismisses
- compact issue indicator persists
- critical state cannot be dismissed when the screen is unusable

### Technical details

- raw error code shown correctly
- raw message shown correctly
- Copy controls work

### Auto retry

- transient failures retry
- deterministic failures do not
- escalation occurs after retry exhaustion

### Accessibility

- semantic labels
- focus behavior
- expand/collapse state
- retry progress announcements

---

# UX Examples

## Local

```text
Session details

⚠ Session details couldn't load
We couldn't retrieve the latest session information.

[Retry]   Technical details ›
```

Use Option 2.

---

## Major

```text
╭─────────────────────────────────────╮
│ ⚠ Some content couldn't load         │
│                                     │
│ 2 requests failed                   │
│                                     │
│ ▸ Messages                  [Retry] │
│ ▾ Session details           [Retry] │
│                                     │
│   Technical details                 │
│   Code: 503 SERVICE_UNAVAILABLE     │
│   Raw: The server is busy...        │
│                                     │
│                 [ Retry all ]       │
╰─────────────────────────────────────╯
```

Use Option 1.

After dismissal:

```text
⚠ 2 issues                 Retry all · Details
```

and optionally inline states.

---

## Critical

```text
        ⚠

Can't reach Ronens-MacBook

This session can't continue until
the connection is restored.

        [ Retry ]

Technical details ›

        [ Go back ]
```

Use Option 1 as a blocking state.

---

# Important Design Decision

If choosing strictly between the two UI concepts:

> **Use Option 1 as the core system.**

Threadbase needs the ability to show one visually dominant recovery surface containing one or several independent errors.

Option 2 is still valuable, but it should be used for:

- genuinely local failures
- contextual recovery
- persistent state after a major error sheet is dismissed

Do not make Option 2 the primary global error architecture.

---

# Expected Workflow

Please proceed in this order:

1. inspect the relevant code
2. identify current error flows
3. present a concise implementation plan with the real files/components/hooks you intend to change
4. call out any architectural uncertainty or conflict
5. implement the solution
6. add/update tests
7. run the relevant test suite / lint / typecheck
8. summarize:
   - files changed
   - behavior added
   - error classifications introduced
   - tests added
   - any remaining follow-ups

Do not redesign unrelated UI.

Preserve the existing Threadbase design language and existing architecture wherever reasonable.

Favor a focused refactor over a large rewrite.
