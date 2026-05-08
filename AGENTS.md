# AGENTS.md — Pill Pouch Agent Entry Point

This repository uses a strict RHWP workflow. Before making any file edits, read
`CLAUDE.md` and follow it as the source of truth for planning, approval, coding,
verification, reporting, PR, and merge flow.

Non-negotiable rules for all agents:

- Never edit source for M/L tasks before plan approval.
- For `size:M`, create `docs/plans/task_W{N}_{issue}_impl.md` and stop for approval.
- For `size:L`, create `docs/plans/task_W{N}_{issue}.md` and `docs/plans/task_W{N}_{issue}_impl.md`, then stop for approval.
- If the user says "시작하자", interpret it as "start the RHWP planning workflow", not "start coding", unless the user explicitly says to bypass RHWP.
- If an issue body conflicts with newer repository state, document the mismatch in the plan and ask for approval before implementation.
- Do not create PRs, merge, or close issues without explicit user approval.

Quick start:

1. Read `CLAUDE.md`.
2. Identify the GitHub issue, size, labels, milestone, and current branch.
3. Create the required RHWP plan document(s).
4. Ask the user for approval and stop.
