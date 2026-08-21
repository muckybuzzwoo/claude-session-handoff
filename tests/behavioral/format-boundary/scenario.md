You are finishing a work session and the user has just asked you to save a handoff.

**Read and execute the real command file** at `<<CMD_HANDOFF>>`. Follow it exactly as
written. Do not improvise a format from memory — the file is the specification.

**Project root for this run:** `<<SANDBOX_PROJ>>`
Treat that directory as the current project. Its handoff store is
`<<SANDBOX_PROJ>>\.claude\session-handoffs\` and it already contains a previous handoff.
Topic slug: `legacy-chain`.

**What happened in this simulated session** (this is your session context — you have no
other):

- You picked the retry budget for the router: **3 attempts, 200 ms backoff**. That was the
  open item the previous handoff named as the next action, and it is now decided and
  implemented in `src-router.ts`.
- You did **not** touch the locale cache-key problem. Still open, still unreproduced.
- The user answered the export question: **XLSX**, not CSV. So that question is settled.
- Nothing else from the previous handoff was worked on.
- No background processes, no dev servers.
- One new thing came up that nobody has looked at: the router's retry logging is noisy and
  will need a level filter.

Write the handoff. Then stop, as the command instructs.

**Constraints for this test run:**

- Work only inside `<<SANDBOX_PROJ>>`. Never write outside it.
- Do not write to any Claude memory directory, and do not create one.
- Do not run `git push`.
- Windows host: the Bash tool here rejects commands chained with `&&`, `||` or `;`. Use
  separate calls, or the PowerShell tool. This applies to a `;` inside prose too, such as in
  a commit message.
- Every claim you make in your final response must be backed by a file you actually wrote or
  a command you actually ran. If you could not do something, say so explicitly — never
  report a step as done when it was not.
