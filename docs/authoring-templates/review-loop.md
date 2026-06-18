# Beginner Review Loop

Every chapter or lab draft should pass through a local Draft -> Beginner Review -> Revise loop before the related issue is closed.

This is an editorial process, not a CI gate. The goal is to make first-principles teaching repeatable without pretending that a script can judge comprehension.

## Workflow

1. Draft the chapter or lab from validated experiments and reviewed sources.
2. Update `docs/reader-knowledge.md` with any concepts the draft introduces.
3. Spawn a beginner-review subagent.
4. Give the reviewer the required inputs listed below.
5. Revise the draft or record why a finding is deferred or rejected.
6. Run normal verification.
7. Close the issue only after the review happened or was explicitly deferred.

## Reviewer Inputs

Give the reviewer:

- the chapter or lab file under review,
- `docs/reader-knowledge.md`,
- the reader knowledge section through the previous chapter,
- the relevant transcript under `experiments/transcripts/`,
- the relevant research note under `research/notes/`,
- the relevant authoring template,
- any issue acceptance criteria.

Do not tell the reviewer what you think is weak. The review is more useful when it is not anchored by the drafter's opinion.

## Reusable Reviewer Prompt

```text
You are reviewing chapter or lab content for a reader learning networking for the first time.

Assume the reader knows only the concepts listed in docs/reader-knowledge.md through the chapter immediately before the file under review.

Be critical. Do not edit files.

Review for:
- undefined terms,
- reasoning jumps,
- weak or missing mental models,
- weak or missing diagrams,
- commands that can be copied without understanding,
- hidden state assumptions between chapters or labs,
- long-running processes that require unclear shell/process handling,
- tooltip density that makes ordinary prose feel like a vocabulary quiz,
- missing code block titles where execution context or generated config file names matter,
- places where the draft assumes operational knowledge not yet taught,
- misleading simplifications,
- mismatch between the draft and the validated transcript or cited research.

Return:
1. Findings ordered by severity.
2. Concrete file and section references.
3. Actionable revision suggestions.
4. A short note on what works well, after the findings.
```

## Finding Decisions

After review, classify each finding:

- Accepted: revise the draft now.
- Deferred: create or link a follow-up issue and explain why it is not part of this pass.
- Rejected: explain why the finding does not apply.

Do not close the chapter or experiment issue with untriaged beginner-review findings.

## Local Tracking

Use issue comments to record:

- reviewer date,
- reviewed files,
- accepted findings,
- deferred findings and linked issues,
- rejected findings with reasons.

For now, use existing labels such as `chapter`, `experiment`, `conceptual`, and `v0.1`. If the process starts getting missed, add a `needs-beginner-review` label later.

## Done Criteria for Chapter and Lab Issues

A chapter or lab issue is not done until:

- the draft follows the relevant authoring template,
- `docs/reader-knowledge.md` is updated when new concepts are introduced,
- a beginner review has been run or explicitly deferred,
- accepted review findings have been addressed,
- deferred review findings have follow-up issues or clear notes,
- normal verification commands pass.
