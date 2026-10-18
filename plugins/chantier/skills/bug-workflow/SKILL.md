---
name: bug-workflow
description: Carry a bug from report to MR — assess, gate, regression test first, fix, verify. Use on every bug found, whether reported by a human or met by an agent during its own work, and on a tracker issue (#NNN) labelled bug.
metadata:
  compatibility: Requires spec-kit 1.2+ with the bug extension (speckit-bug-assess, -fix, -test) and the tracker CLI named in the project file (.specify/workflow-project.md)
  author: herdr-claude-stack
---

<!--
  PORTABILITY NOTE — stack-agnostic. Project specifics live in the project file `.specify/workflow-project.md`
  (VCS, gates, tracker, validation pages), shared with chantier:dev-workflow and chantier:idea-workflow.
-->

## User Input

```text
$ARGUMENTS
```

Either a tracker issue ref (`#NNN`) or a bug report as text (symptom, steps, logs). Empty → **STOP** and ask for it.

Read the project file `.specify/workflow-project.md` and `gate.md` of chantier:dev-workflow before the first step. No
project file → **STOP**: say it is missing and point to the template in chantier:dev-workflow (Annex).

## Pipeline

1. **Input.**
   - **Issue ref** → read it with the tracker CLI, comments included (PROJECT TRACKER NOTE). The slug is
     `<iid>-<kebab>` (2–4 words from the title).
   - **Report text** → the issue does not exist yet: the slug is `<kebab>` until step 3 creates it.
   Never pass a private tracker URL to a skill; pass the text read from the CLI.

2. **`speckit-bug-assess`** — args: the issue or report text, then `slug=<slug>`. It writes
   `.specify/bugs/<slug>/assessment.md`: verdict (valid | likely valid, needs reproduction | invalid), severity
   (critical / high / medium / low), root cause, Proposed Remediation, Files likely to change, Tests to add or update,
   Risks. Read-only on the code.

3. **Issue** — report input only: create the issue (label and milestone per the tracker note, body = the report and
   the assessment summary), then rename `.specify/bugs/<kebab>/` to `.specify/bugs/<iid>-<kebab>/`.

4. **GATE — the assessment summary as a comment on the issue** (verdict, severity, cause, remediation, files, tests,
   risks; it is the G1 card where the project has one), shown as a validation page per chantier:dev-workflow
   (`gate.md`): verdict and severity, cause with `file:line`, proposed fix, planned regression test. Who validates:
   PROJECT TRACKER NOTE. Wait for the go.
   - **invalid** → the comment says why; the issue goes back to the human per the tracker note. Stop.
   - **likely valid, needs reproduction** → the fix starts with reproducing it; a bug that cannot be reproduced where
     you run goes to the gate with that said, not guessed at.

5. **Branch** — `fix/<iid>-<kebab>` cut from the integration branch (PROJECT VCS NOTE). The issue gets the
   in-progress label and a comment naming the branch.

6. **Regression test first** — write the test the assessment names, run it, see it **fail** for the bug's reason. A
   test that passes before the fix proves nothing: rewrite it.

7. **`speckit-bug-fix slug=<slug>`** — applies the remediation and writes `fix.md` (Status applied | partial |
   not-applied). Partial or not-applied → pause and surface why on the issue; never widen the fix past the
   assessment without a new go.

8. **`speckit-bug-test slug=<slug>`** — writes `test.md` (Result verified | partial | failed). The regression test now
   passes. A bug that only shows on another platform and cannot be reproduced here is **partial**: post a field
   recipe on the issue (steps, what to look at, expected result) and set the field label per the tracker note.
   failed → back to step 7, at most twice, then pause.

9. **PROJECT GATES** — run every gate that applies, read each log, report skipped gates as skipped.

10. **Commit and hand-back** — one commit: the fix, the regression test, `.specify/bugs/<slug>/`. The MR (only on an
    explicit push accord) references the issue with the project's verb, never an auto-close one; its recipe (G2) is
    built from `fix.md` and `test.md`, and shown as a page per chantier:dev-workflow (`gate.md`). Hand back: slug,
    verdict, severity, the commit SHA, the gates, the test result, and the field recipe if any. Never close the issue:
    closure follows the tracker note.
