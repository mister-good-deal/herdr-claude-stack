---
name: idea-workflow
description: Assess an idea before any spec — intake, research, problem, concept, then a go / needs-clarification / kill decision; a go becomes a feature issue and a /dev-workflow run. Use when the maintainer brings an idea that is not yet a feature.
metadata:
  compatibility: Requires spec-kit 1.2+ with the assess extension (speckit-assess-*) and the tracker CLI named in the project file (.specify/workflow-project.md)
  author: herdr-claude-stack
---

<!--
  PORTABILITY NOTE — stack-agnostic. Project specifics live in the project file `.specify/workflow-project.md`
  (VCS, gates, tracker, validation pages), shared with chantier:dev-workflow and chantier:bug-workflow.
-->

## User Input

```text
$ARGUMENTS
```

The idea, in any form: text, a tracker issue ref, a codebase pointer. Empty → **STOP** and ask for it.

Read the project file `.specify/workflow-project.md` and `gate.md` of chantier:dev-workflow before the first step. No
project file → **STOP**: say it is missing and point to the template in chantier:dev-workflow (Annex).

## Role

This is a conversation with the maintainer, not a run: each step ends by showing its file in a few lines and asking
what it leaves open. A `[NEEDS CLARIFICATION]` marker is settled by correcting the file with the answer — never by
rerunning the step. No code, no spec, no design of the implementation before a **go**.

## Pipeline

All files go in `.specify/assessments/<slug>/` (slug: 2–4 kebab words, agreed at intake).

1. **`speckit-assess-intake`** — the idea normalized into `intake.md`. A tracker issue is read with the CLI and passed
   as text: never a private tracker URL (the skill only fetches public hosts).
2. **`speckit-assess-research`** — evidence for and against: users, prior art, data, the codebase → `research.md`.
3. **`speckit-assess-define`** — who hurts, what, goals, non-goals, success metrics → `problem.md`.
4. **`speckit-assess-shape`** — 2–3 solution options with scope and trade-offs → `concept.md`. A visual idea is
   shaped with 2–3 prototypes in the repo (PROJECT VCS NOTE), shown to the maintainer, not described.
5. **`speckit-assess-decide`** — the verdict in `decision.md`: go | needs-clarification | kill. The verdict is the
   maintainer's; the skill drafts it, and the gate is a validation page per chantier:dev-workflow (`gate.md`): the
   decision table and the options from `concept.md`.
   - **go** → create a feature issue (design-kind label, milestone and parent per the PROJECT TRACKER NOTE) whose
     description carries `decision.md`, then `/dev-workflow` with that decision as the description.
   - **needs-clarification** → the open questions stay in `decision.md`; resume at the step they belong to.
   - **kill** → stop; the files stay as the trace of why.

Commit `.specify/assessments/<slug>/` on the branch the VCS note allows (one commit, at the verdict). Hand back: the
slug, the verdict, the issue ref for a go.
