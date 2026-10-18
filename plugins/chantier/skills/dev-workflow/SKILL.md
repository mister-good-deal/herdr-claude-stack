---
name: dev-workflow
description: Coordinate a feature through the Spec-Kit workflow, tracker issues, role assignment, implementation with convergence, verification and review. Use for a complete development workflow or a run stopped at a requested stage.
metadata:
  compatibility: Requires spec-kit 1.2+ project structure with .specify/ directory, the speckit-* skills, and the tracker CLI named in the project file (.specify/workflow-project.md)
  author: herdr-claude-stack
---

<!--
  PORTABILITY NOTE — this skill is STACK-AGNOSTIC. The project specifics live in the project file
  `.specify/workflow-project.md` at the repository root, shared with chantier:bug-workflow and chantier:idea-workflow:
  `PROJECT VCS NOTE`, `PROJECT GATES`, `PROJECT TRACKER NOTE`, `PROJECT VALIDATION PAGES`. On import into a new repo,
  write ONLY that file (template: Annex below). This plugin is the canonical copy of the three workflow skills.
-->

## User Input

```text
$ARGUMENTS
```

`$ARGUMENTS` is the feature description forwarded verbatim to `/speckit.specify`, optionally preceded by flags:

- `--until <stage>` — stop the pipeline right after that stage and hand back. Stages, in order: `specify`, `clarify`,
  `plan`, `tasks`, `analyze`, `issues`, `assign`, `implement`, `verify`, `review` (default: run to the end). A run
  stopped at `analyze` or `issues` still passes GATE 2 and still makes the Docs commit — the reviewed design is the
  deliverable of a spec-only run.
- `--issues <per-lot|per-task|none>` — granularity of the tracker issues (default `per-lot`, see step 7).
- `--parent <issue-ref>` — the meta/epic issue the feature belongs to (e.g. `#34`). If omitted, look for one in the
  description; if none, ask at GATE 2 — never guess a parent.
- `--unattended` — no human in the loop: never ask a question. Every open question (clarify, a gate, a pause
  condition) goes to `specs/<feature>/questions.md`, each with the default you would pick and why; continue on the
  defaults and STOP at the next gate, with questions.md as the hand-back.

Strip the flags before forwarding the description. If the description is empty, **STOP** and ask the user for it —
never invent one.

Read the project file `.specify/workflow-project.md` and `gate.md` (next to this file) before the first stage: they
are referenced below. No project file → **STOP**: say it is missing and what goes in it, from the Annex template.

## Role

You are the workflow coordinator: you invoke each Spec-Kit skill in order via the Skill tool and carry the feature
from description through implemented and converged tasks, verification and review. The user interacts ONLY at the
three gates below; everything else runs without them. Never skip a gate, and never ask the user anything a skill
output, the codebase, or the tracker already answers.

## Gate visibility

Open EVERY gate message with the pipeline banner so the user sees where they are and what remains. Render it in a
fenced `text` code block (markers: `✔` done, `◉` you-are-here / waiting on user, `·` pending, `✘` blocked, `⏹` the
`--until` stop) and update markers to the real state at each render:

```text
specify ─▶ clarify ─▶ plan ─▶ tasks ─▶ analyze ─▶ issues ─▶ assign ─▶ implement ⇄ converge ─▶ verify ─▶ review
   ✔      ◉ GATE 1     ·        ·        · GATE 2   ·         · GATE 3       ·          ·            ·         ·
```

At **Gate 3** the banner is followed by the agent Gantt (see step 9). Never replace the gate content with the
visuals — they frame it.

Each gate also opens a **validation page**, per `gate.md` next to this file (open, ask, close): the page carries the
banner, the content and the ask; the terminal keeps the question in one or two lines. An `--unattended` run opens
none.

## Commit discipline (NOT optional)

Invoking this workflow **is** the maintainer's standing authorization to COMMIT at the four milestones below — no
separate ask per commit. Pushes and MRs stay separately gated: never push a branch or open an MR without an explicit
request. Before the first commit, make sure you are on the branch the PROJECT VCS NOTE allows; if the repo's git-flow
forbids committing on the current branch, cut the feature branch first per that flow. Each commit must leave the
tree in the state the preceding gate certified — stage only the feature's own changes, and exclude tooling churn
that isn't part of the feature.

Commit at exactly these points, in order:

1. **Docs** — ONE commit, right after GATE 2 is approved **and the issues are created and linked** (step 7): the
   spec-kit artifacts under `specs/<feature>/` (spec, plan, tasks with their issue links, and any research /
   data-model / contracts / quickstart / checklists). The reviewed, frozen design — with its tracker mirror.
2. **Dev** — after Post-implement verification is green: the implementation. Choose **1 to 10** commits along the
   work's natural seams (per lot, per rail/crate, or a single commit when the change is small) — never more than
   10, never one-commit-per-task. Every committed state must be green: the gates pass at each dev commit, not only
   at the last. In fleet mode the lot agents make these commits on their own branches; the coordinator makes none.
3. **Review** — ONE commit, after `/code-review max --fix` and the re-run gates are green: the review fixes.
4. **Finish** — ONE commit, the convergence record: `tasks.md` with its `Phase N: Convergence` sections and final
   ticks, and the issue checklists resynced to it.

If a milestone produced no change (review found nothing to fix, converge appended nothing), SKIP its commit and say
so — never an empty commit. Write each message in the repo's commit convention; the milestone is the unit, so a
message describes that milestone's slice, not the whole feature.

## Pipeline

1. **`speckit-specify`** — pass the description verbatim as args. Autonomous. If the VCS note forbids the feature
   branch the script would create (e.g. the run commits on the release branch), create the feature directory from
   the template without the branch and export `SPECIFY_FEATURE=<###-short-name>` for every later script call.

2. **`speckit-clarify`** — autonomous to run, but its questions ARE the user's decisions. Relay each clarification
   question to the user via AskUserQuestion (batch them; preserve the skill's options verbatim, add a recommendation
   only when the codebase gives evidence for one). Feed the answers back so the skill encodes them into the spec.
   When the description already carries a decision record (design notes, an issue synthesis, a `decision.md`),
   answer from it and only relay what it leaves open.
   - **A visual choice** (layout, component, interaction) is settled by 2–3 prototypes in the repo, shown to the
     user, never by a text option. How to build and show them: PROJECT VCS NOTE.

   > **GATE 1 — exits with the user's clarify answers recorded.** If clarify finds nothing to ask, note that and
   > continue. Show the banner with one line per pending clarify question theme before the AskUserQuestion batch.

3. **`speckit-plan`** — autonomous. Then read the plan's Constitution Check + Complexity Tracking table.

4. **`speckit-tasks`** — autonomous.

5. **`speckit-analyze`** — autonomous, read-only: the cross-artifact scan (spec ↔ plan ↔ tasks ↔ constitution)
   before any code. Fix the HIGH/MEDIUM findings in the artifacts yourself; keep the CRITICAL ones for GATE 2.

6. **GATE 2 — plan & tasks review.** Banner first, then present to the user, compactly:
   - analyze's CRITICAL findings (a constitution MUST violated, a requirement with zero coverage), each with its
     proposed remediation — they need an explicit decision before continuing
   - any Constitution-check deviation (each needs an explicit accept/reject — a rejected deviation goes back to
     `speckit-plan` with the user's constraint)
   - a phase map of tasks.md so the shape of the work is visible at a glance — this map IS the lot list of step 7:

     ```text
     Lot / Phase    Tasks        What it builds
     Setup          T001–T003    scaffolding, deps
     Foundational   T004–T008    schema + migrations ⚠ touches data
     US1            T009–T014    ingestion endpoint + UI
     Polish         T015–T017    tests, docs
     ```

   - flag inline (⚠) anything that touches data, API contracts, security, or migrations
   Wait for the user's go before continuing. This is a 2-minute review, not a re-litigation: default to proceeding
   unless the user objects.

7. **Issues — decline the frozen tasks into the tracker.** Autonomous, right after GATE 2 approval, before the
   Docs commit (so the commit carries the links). Skipped when `--issues none` or the project has no tracker.
   - **Granularity.** `per-lot` (default): one issue per lot of the phase map — each tasks.md phase (Setup,
     Foundational, Polish) and each user story. A lot is what one agent takes end-to-end (one branch, one MR).
     `per-task`: one issue per task, reserved for very small features.
   - **Content.** Title `<feature short title> — <lot title>`; body in the project's issue language and house
     style, containing: the lot's goal (the story's Goal / the phase's Purpose), the **task list verbatim** as
     tracker checkboxes (`- [ ] T0xx …`, file paths kept), the independent test / acceptance of the story, the
     lots it depends on, and the paths of spec.md / plan.md / tasks.md as they will exist at the Docs commit.
     Milestone, labels, parent and dependency form per the PROJECT TRACKER NOTE; every issue related to the parent
     issue, and the parent's own checklist extended with the new issues.
   - **Write-back.** In tasks.md: an `## Issues` table right after the header (lot ↔ issue ref ↔ task range) and
     the issue ref appended to each phase header (`## Phase 3: User Story 1 — … (#NNN)`); in spec.md's header,
     the parent issue ref. The Spec-Kit artifacts stay the source of truth for the design; the tracker is the
     execution mirror.
   - **Idempotence.** Never create duplicates: a lot whose header already carries an issue ref is updated
     (description resynced), not recreated. Report the created/updated refs in the banner message.

   **Once the issues are linked, make the Docs commit** (Commit discipline #1) before moving on to assignment.

8. **`speckit-agent-assign-assign`** then **`speckit-agent-assign-validate`** — autonomous. If validate reports
   problems, fix the assignments and re-validate; loop until clean. Only escalate to the user if validation fails
   because no suitable agent exists for a task.

9. **GATE 3 — implement greenlight.** Banner first, then an **agent Gantt** derived from `tasks.md` (lots, [P]
   markers, same-file conflicts) and `agent-assignments.yml` (task → agent). One row per (lot, agent) pair;
   columns are execution slots — [P] tasks on different agents share a slot, everything else is sequential. This
   is an ordering/parallelism view, NOT a time estimate; say so.

   ```text
   Slot ▸               1     2     3     4     5
   Setup (#120)
     default            ███ T001–T003
   Foundational (#121)
     backend-architect        █████ T004–T008
   US1 (#122, parallel)
     frontend-developer             ████ T009–T012
     api-tester                     ██   T013–T014
   Polish (#123)
     code-reviewer                              ██ T016–T017
   ```

   Below the chart: per-agent task counts, the execution mode (single-session or fleet, step 10) and a rough sense
   of the spend. Wait for explicit go — this is the big token/time commitment.

10. **Implement ⇄ converge** — autonomous, in one of two modes decided by the PROJECT TRACKER NOTE:
    - **Single-session mode** — `speckit-agent-assign-execute`: in-process sub-agents, one per task, on the current
      branch. The coordinator ticks the tasks in tasks.md and in each lot's issue as they complete. Then
      `speckit-converge` (full scope): it appends a `Phase N: Convergence` to tasks.md with the unbuilt work;
      implement those tasks the same way, and rerun converge until it reports « Converged ».
    - **Fleet mode** — one agent **session** per lot (its issue), each in its own worktree and branch cut per the
      VCS note, launched by the coordinator with the lot's full context: the issue URL, its task subset, the paths
      of spec/plan/tasks, the branch, the gates, the issue-lifecycle rules below. Each lot agent runs the same loop
      **scoped to its lot** — `speckit-converge` with the scope as args (« scope: US2, T017–T021 ») — before its
      MR, opened per the project's coordination runbook, then a message to the coordinator; the coordinator
      reviews, orders and merges per that runbook. After the **last** lot merges, the coordinator runs a **full**
      converge on the integration branch; if it appends tasks, they become a « Convergence » lot (an issue per
      step 7, an agent, an MR).
    - Tasks added by converge also enter the checklist of their lot's issue.
    - **Ceiling: 3 converge rounds** per scope. A 4th needed round → pause and surface the remaining gap.

    THREE standing pause conditions override autonomy mid-run in both modes:
    - a task needs a decision with real impact (schema change beyond the spec, API contract ambiguity, anything
      destructive or outward-facing) → pause, AskUserQuestion, resume
    - a task fails twice for the same cause → pause and surface it instead of burning further attempts
    - converge has not converged after 3 rounds → pause

    After each completed lot, re-render the Gate 3 Gantt as a progress view — replace finished bars with `✔`, mark
    the running row `▶`, failed rows `✘` — so the user can glance at any pause or lot summary and know exactly
    where execution stands.

## Issue lifecycle during implementation

The tracker mirrors progress; the Spec-Kit files stay the design of record. Whoever executes a task (sub-agent,
lot agent, coordinator) keeps both in step:

- **Start of a lot** → the lot's issue gets the in-progress label (per tracker note) and, in fleet mode, a comment
  naming the branch and the agent session.
- **Task done** → tick it in tasks.md AND in the issue's checklist (edit the description; the checkbox line is the
  same text, so a plain string replace is safe).
- **Convergence task added** → append it to the lot issue's checklist, same text as in tasks.md.
- **Blocker / decision needed** → a comment on the issue, mirrored to the coordinator; never a silent workaround.
- **Lot done** → MR opened per the coordination runbook, referencing the issue with the project's reference verb
  (see tracker note — some projects forbid auto-close); the ready label set; a closing comment summarizing what
  shipped and what was left out.
- **Never close an issue** unless the tracker note says who may: closure is a human verdict in most projects. Never
  create issues outside the repository the git remote points to.

## Post-implement verification (NOT optional)

Never trust a sub-agent's "done". After implement ⇄ converge has converged, re-run **the PROJECT GATES yourself**
and fix what fails before reporting. Always start with `git status` — no stray stashes, no unexpected deletions or
moves (surface anything you didn't cause) — then run the gates for the rails the feature touched. Report results
faithfully: failing output verbatim, skipped steps named as skipped, never a green you didn't see. **Once the gates
are green, make the Dev commit(s)** (Commit discipline #2 — 1 to 10, each state green; fleet mode: verify each lot's
branch at MR review instead).

## Post-implement review (NOT optional)

11. **`/code-review max --fix`** — max-effort review of the branch diff (`git diff <base>...HEAD`, or the working
    tree if uncommitted), applying the surviving findings to the working tree. After the fixes land, **re-run the
    Post-implement verification gates** (a fix that breaks a gate is reverted, not forced). Report what was fixed
    and what was skipped (with the reason). Do not let a sub-agent's "done" stand — verify the diff yourself.
    **Once the re-run gates are green, make the Review commit** (Commit discipline #3 — skip it if nothing was
    fixed), then the **Finish commit** (Commit discipline #4).

## Hand-back

Summarize what shipped against the spec's acceptance criteria, plus the analyze, converge and review outcomes
(CRITICAL findings and their resolution, convergence rounds and tasks added, fixed bugs, any declared caveats), the
tracker issues created/updated (refs, lots, state), and the milestone commits you made (Docs / Dev ×N / Review /
Finish, with any skipped and why). The four milestone commits ARE part of the workflow (see Commit discipline) —
you make them without asking. **Pushes and MRs are NOT**: they stay behind an explicit user request. State the
branch the commits landed on and that it is unpushed, and offer to push + open the MR as the next step. For a
`--until` run, say which stage it stopped at, what the next stage would do, and how to resume (`/dev-workflow` with
the same description resumes from the existing `specs/<feature>/` artifacts). For an `--unattended` run, the
hand-back is the path of `questions.md` and the gate it stopped at.

## Annex — project file template (`.specify/workflow-project.md`)

```markdown
# Workflow project file — read by /dev-workflow, /bug-workflow and /idea-workflow

## PROJECT VCS NOTE
- Integration branch, branch naming for features and fixes, where the version bump lives.
- Commit rules (staging, trailer); what guards a push or an MR.
- Tracked artifacts (`specs/`, `.specify/bugs/`, `.specify/assessments/`); how prototypes are served and shown.

## PROJECT GATES
- The local gates to run before a hand-back (or the doc that lists them).

## PROJECT TRACKER NOTE
- Tracker and CLI (create, read, edit, link); issue body language and sections; private host or not.
- Milestones, parent issue, dependencies, labels and lifecycle; the MR reference verb (never an auto-close one).
- Closure rules, who validates the bug gate, the human gates (G1/G2/G3) if any, the execution mode (solo or fleet).

## PROJECT VALIDATION PAGES
- Renderer (command that opens a markdown page) and how its components map to the roles in gate.md.
- Who shows the page to the human; the language of the pages.
```
