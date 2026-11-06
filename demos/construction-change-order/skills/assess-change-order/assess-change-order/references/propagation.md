# Propagation: which phases move, and by how much

One ordered rule, applied to the project's Current rows after the document's changes have been read. The rows as read are the **before** values; work on a copy and never overwrite them in your working. Dates are calendar dates (`2026-11-06`); "days" are calendar days.

## Inputs
- The document's changes: for each numbered change section, the phase number, the days, the cost.
- The Current rows: `PhaseNo`, `DependsOn` (one predecessor phase number or blank), `Start`, `End`, `Cost`, `PhaseStatus`.

There are no cycles and every phase has at most one predecessor. A `DependsOn` naming a phase that is not on the list is a stop (the skill puts the row back to `Accepted`).

## Rule
Process the document's changes **in phase-number order**, one at a time. For each change on phase P:

1. **Start point.** If an earlier change in this document already slid P (step 3 below), start from P's slid dates; otherwise from its before dates.
2. **Direct.** New End of P = its End (after any slide) + the change's days. New Cost of P = Cost + the change's cost. P's Start does not move further (it keeps any slide from step 1). Mark P **Direct** (a phase that was slid earlier and is also changed is Direct).
3. **Walk the dependents.** Every row whose `DependsOn` is P, then every row whose `DependsOn` is one of those, and so on: a dependent is handled only after its predecessor's New End is known, and rows at the same depth are taken in phase-number order. For each dependent D with predecessor Q:
   - `Complete`: never moves.
   - `Not Started`: slides whole, keeping its length. Gap = D's before Start − Q's before End. New Start = Q's New End + gap. New End = D's before End + (New Start − D's before Start). "Before" is always the value as read from the list, even when D is walked more than once in the same document; a second walk recomputes from Q's latest New End, it never adds to a previous slide. Forward only: if that would move D earlier than before, D does not move.
   - `In Progress`: Start stays. New End = the later of D's before End (or its Direct New End, if this document changed it) and Q's New End.
   A dependent that moved and is not Direct is **Shifted**. A dependent whose dates did not move keeps its before dates and no mark.
4. A later change in the same document on a phase that was already Shifted starts from the slid dates (step 1) and makes it Direct; its dependents are walked again from the new End.

Then:

- **Informational** = every phase that is neither Direct nor Shifted. Nothing moves, cost unchanged.
- **Days moved** for a phase = New End − before End (0 for Informational).
- **Project after**: Current Completion = the latest New End over all phases (Informational phases count with their before End). Current Total = the sum of New Cost over all phases. The before values come from the Projects row (`CurrentCompletion`, `CurrentTotal`); the sum of the Current rows' `Cost` must equal `CurrentTotal` before the change, or report the difference and stop.

## Worked example (shape only; the numbers come from the lists on the day)
A change of +21 days on Phase 3 (ends 6 Nov → 27 Nov, Direct). Phase 4 depends on 3, Not Started, gap 10 days, length 10 weeks: it slides to start 7 Dec and end 12 Feb (Shifted). Phase 6 depends on 4: slides the same 21 days (Shifted). Phase 5 depends on 2 and does not move (Informational). Completion moves from Phase 6's before End to its New End.
