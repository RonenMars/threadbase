## D-8, from a different angle

I went and read what the client actually does, because I think the escalation has been answering a question the code has already partly settled.

**The pin lives on the client, and the client never asks the server.** Both channels decide identically, from client-held state only:

```js
// authed-fetch.ts:177          // ws-client.ts:190
if (isPinned(target))            const pinned = requireEncryption === true
  return sealedFetch(...)          && !!serverPublicKey
return plaintextFetch(...)
```

`isPinned` is `requireEncryption === true && serverPublicKey && id`. Nothing in it consults `/api/info`, the server's current flag, or anything the server says at connect time. And the only path that sets `requireEncryption` to `false` anywhere in the app is `ServerEncryptionSection.tsx:49` — an `onPress`. **A user tap. There is no server-driven path that clears a pin.**

### What that does to the threat model

So take the feared scenario — someone sets `THREADBASE_FEATURE_E2EE=0` on a supervised box and it silently persists forever — and ask what actually happens to each population:

**Pinned devices.** The client sends a sealed request regardless. The server no longer speaks E2EE, so it refuses. The device breaks — visibly, immediately, on every request. That is not a silent downgrade; it's a loud outage. Every paired phone becomes a klaxon that no boot warning could match for reach, because the operator's users are holding it.

**New or unpaired devices.** These pair in plaintext against a downgraded server and never know encryption was expected. **This is the real exposure, and it is first-contact, not downgrade.** None of the three options on the table touch it.

**The operator themselves.** Believes the box is encrypted; it isn't. Genuine, and this is what option 3's warning actually addresses.

If that holds, D-8 as written is a **mechanism** rule ("no env var may hold encryption off") defending against a harm the mechanism largely cannot cause, while the harm it *can* cause is untouched by all three options.

### Two options nobody wrote down

**Option 4 — make the rule about consequence, not about rung.** *A boot that would serve plaintext while N > 0 pinned devices exist must announce itself (or refuse to start).* The server already knows this at boot — `server.ts:2401`'s own comment says "Called after `devicesRepo` opens, since the count is the point." This needs no registry exemption, keeps every flag uniform, scales with actual risk rather than with which rung someone used, and — the part I like — **survives someone inventing a fourth way to set a flag**, which options 1 and 3 do not, since both enumerate rungs.

**Option 5 — asymmetric on direction, not on source.** Env may *always* turn E2EE on. Turning it *off* while pinned devices exist requires an argv-level act. That preserves the documented stage-1 enable path, which is precisely what option 1 breaks, and confines the special case to the one direction that carries risk. The rule states in one line: *turning encryption on is always easy; turning it off when devices depend on it must be visible.*

### Three things I'd want checked before trusting my own argument

1. **Does the pairing flow have a plaintext fallback?** If first contact is the residual risk, that's where the actual work is — and it would be a different PR than any R2 option.
2. **What does a pinned device *show* the user when the server has E2EE off?** If it surfaces "The server is busy; retrying shortly," that's the same defect class C1 just fixed, and the loud-outage argument gets much weaker — an outage that lies about its cause isn't loud, it's confusing.
3. **Whether `requireEncryption` survives everything it should** — reinstall, restore-from-backup, `editServer`. The pin is the load-bearing part of my argument, so its durability is the thing worth attacking.

None of this decides R2, and R's document is good — it answered the question as posed. What I think it's missing is that the guarantee D-8 wanted may already be delivered somewhere better than the server: on the client, by a pin only a human tap can remove. If that's right, option 2 gets a lot cheaper than it looks, and options 4/5 get more interesting than 1 or 3.

Where do you want to push on it? I can chase any of those three checks, or argue the other side of my own case — the strongest counter is that the pin protects existing devices while saying nothing about the next one to pair.
