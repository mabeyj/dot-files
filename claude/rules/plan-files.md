# Personal preferences for plan files

When working on a project or task with a large scope, keep track of the overall
plan in a plan file: a Markdown file in the root of the repository named like
`some-project-plan.md`. For simple tasks like a small bug fix or improvement, a
plan file is not necessary.

If a project spans multiple sessions, the plan file is the source of truth
for the plan and the work that has been done so far, stored in a place that
will not get easily lost or purged.

The plan is flexible. It is expected that things will come up as work
progresses. Keep the plan file updated when the scope changes, new tasks are
discovered, or tasks are completed.

A plan file is left untracked until the project is near completion, when it
becomes less of a working document and more of an archivable reference.

## Organization

Keep things organized into sections with headings. Some common sections, all of
which are optional:

- **Current state:** A concise overview of the current state of the project.

- **Decisions:** A list of important decisions made which might affect the
  scope or trajectory of the project.

- **Open questions:** Any open questions which have not been answered yet or
  have been deferred for later in the project.

- **Phases:** Each phase is its own numbered section like "Phase 2". If a phase
  is split after the fact, it could be lettered like "Phase 2b". Prefix
  completed phases with "(DONE)" in the heading. Begin with a checklist of
  tasks in the phase. Describe tasks concisely. Any additional context or
  details can go in a subsection.

- **Follow-ups:** Accumulates any optional or low-priority follow-up tasks.
  Follows the same format as phases: checklist first, then subsections for
  further detail.

- **Findings:** Subsections for any detailed findings or results worth
  recording. These could be things like investigations, bug hunting, steps to
  reproduce, or deep dives into library code to answer a question. This would
  be the place to store technical details that would be helpful if it is
  necessary to try to reproduce the same results in the future. It may be
  worthwhile to record the version or date if the results may change in the
  future, such as after a new upstream release.

- **Appendices:** Subsections for any miscellaneous facts, data, or procedures
  that might be referenced by other sections. Could be lettered like
  "Appendix A".

## Formatting

For checklists, add a blank line between items for readability.

For normal lists, add a blank line between items that are long (multiple lines)
for readability. For several items that are short (single line), keeping them
compact without a blank line in between is fine.

## Example

```
# Project name

A description of the project scope or goals.

## Decisions

- Use this instead of that.

- Another decision...

## Open questions

- Is this different on production?

- Another question...

## (DONE) Phase 1: Database models

- [x] Create a migration for new model

- [x] Create a `NewModel` class

### Model attributes

Going into detail about a specific task...

## Phase 2a: Back-end views

## Phase 2b: Front-end views

## Follow-ups

## Findings

### Upstream bug investigation

## Appendices
```
