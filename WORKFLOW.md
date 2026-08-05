# WORKFLOW — how the designer Claude (claude.ai) and Claude Code coordinate

**Roles.** This chat's Claude = designer/PM: research, design docs, decisions, backlog, review. Claude Code = engineer: builds from `docs/` + `BACKLOG.md`, asks questions via `docs/questions-for-design.md`. The repo is the single source of truth; neither Claude relies on chat history the other can't see.

**Kickoff (tonight).**
1. Drop this seed's contents into the repo root; commit and push.
2. In your desktop folder (cloned repo), run `claude` — Claude Code auto-loads `CLAUDE.md`. First prompt: *"Read CLAUDE.md, docs/, and BACKLOG.md, then start Milestone 1. Commit per item."*
3. Let it run; it will append design questions to `docs/questions-for-design.md` instead of blocking.

**The loop while we design.**
- Design changes happen in chat with me → I regenerate the affected `docs/` file(s) (always the doc, never chat-only) → you replace the file(s), commit → tell Claude Code "docs updated, re-read decisions-log and X."
- Claude Code's questions: paste `docs/questions-for-design.md` to me (or I read it directly if the GitHub connector is hooked up in chat) → I answer into `decisions-log.md`/brief updates → back into the repo.
- Review: paste build output/screenshots or PR diffs to me for design review; with the GitHub connector I can read the repo, review commits, and file issues myself.

**Conventions.** `docs/decisions-log.md` newest entries are authoritative. `[PLACEHOLDER]` in docs and `// PLACEHOLDER` in code mark Claude-invented values. Open questions live in `docs/open-questions.md` and are Aimee-only to resolve.

**Reference docs for Claude Code.** `design-brief-v0.md` (build this), `research-pass-2.md` (why decisions were made), `research-pass-3-catalogs.md` (symbol/gambit catalog raw material for the Content module).
