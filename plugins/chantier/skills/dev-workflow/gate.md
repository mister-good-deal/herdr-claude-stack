# Validation page — shared by /dev-workflow, /bug-workflow and /idea-workflow

Every human gate opens a page in a browser next to the terminal; the question stays in the terminal, in one or two
lines. The same holds for the G2 card of an MR. The renderer, its components, who shows the page and its language come
from the `PROJECT VALIDATION PAGES` block of the project file.

## Rule: open, ask, close

1. **Write** the page as markdown in the session scratchpad — it is a view, never committed.
2. **Open** it with the project's renderer, plus the cited artifacts (spec, plan, tasks, prototypes) in the
   neighbouring tabs.
3. **Ask** in the terminal: what is expected, in one or two lines; the page carries the rest.
4. **Close** the tabs once answered.

Who shows: per the project file. In a direct session the agent does all four steps itself; in a fleet, the lot agent
writes the page in its own scratchpad and sends the path to whoever shows it to the human.

## Page skeleton

The components below are named by role (steps, ask, warning tag, bars, note); the project file maps them to its
renderer. Write issues as `#NNN`; never hand-write a tracker URL.

```html
# #NNN <subject> : <the question in a few words>

<div class="pipe"><span class="ok">specify ✔</span><span class="here">◉ GATE 2</span><span>issues</span>…</div>

<div class="ask"><b>What we need from you:</b> the decision, in two or three lines, and the recommendation.</div>
```

Always at the top: the steps (`.pipe`: `.ok` done, `.here` this gate, `.ko` blocked) and the ask (`.ask`). Then, by
gate:

| Gate | Content after the head |
|---|---|
| dev GATE 1 | each question with its options side by side; a visual choice opens its prototypes in tabs |
| dev GATE 2 | the lot map with its `.warn-tag` ⚠, analyze's CRITICAL findings, the constitution deviations; spec, |
| | plan and tasks in the neighbouring tabs |
| dev GATE 3 | the lots as bars (`.gantt`, `--slots`, bar placed by `grid-column`, `.warn` / `.you` / `.done`) and a |
| | `.note` saying the slots give order, not duration |
| bug gate | verdict and severity, the cause with `file:line`, the proposed fix, the planned regression test |
| idea gate | the decision table and the 2 or 3 options |
| MR G2 | the G2 card of the MR, as written in its description |

The page is in the language the project file names for the human.
