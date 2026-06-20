# Beginner Review Loop

Every chapter or lab draft should pass through a local Draft -> Beginner Review -> Revise loop before the related issue is closed.

This is an editorial process, not a CI gate. The goal is to make first-principles teaching repeatable without pretending that a script can judge comprehension.

Some chapters also need technical review. Beginner review and technical review are separate checks:

- Beginner review asks whether the intended reader can follow the material with only the knowledge already taught.
- Technical review asks whether commands, configs, safety claims, tool behavior, current-practice claims, and simplifications are correct enough to publish.

## Workflow

1. Draft the chapter or lab from validated experiments and reviewed sources.
2. Fill in the metadata block from the chapter or experiment template.
3. Apply `docs/authoring-templates/internet-readiness-standard.md`.
4. Update `docs/reader-knowledge.md` with any concepts the draft introduces.
5. Spawn a beginner-review subagent for substantive explanatory content.
6. Give the beginner reviewer the required inputs listed below.
7. Run technical review when the metadata says it is required.
8. Revise the draft or record why each finding is deferred or rejected.
9. Run normal verification.
10. Close the issue only after required reviews happened or were explicitly deferred with reasons.

## Reviewer Inputs

Give the reviewer:

- the chapter or lab file under review,
- `docs/reader-knowledge.md`,
- the reader knowledge section through the previous chapter,
- the relevant transcript under `experiments/transcripts/`,
- the relevant research note under `research/notes/`,
- the relevant authoring template,
- `docs/authoring-templates/internet-readiness-standard.md`,
- any issue acceptance criteria.

Do not tell the reviewer what you think is weak. The review is more useful when it is not anchored by the drafter's opinion.

## Technical Review Triggers

Technical review is required when a chapter or experiment includes any of these:

- BIRD configuration,
- WireGuard configuration,
- DN42-current guidance,
- real peer or registry work,
- DNS resolver or authoritative DNS configuration,
- firewall or packet-filtering changes,
- route export/import policy,
- host-wide sysctl guidance,
- non-lab network changes,
- security, privacy, abuse, or operational safety claims.

Technical review may be deferred only when the issue is explicitly non-operational, such as a roadmap note, metadata update, or mechanical rename. Record the reason in the issue closeout.

## Technical Reviewer Inputs

Give the technical reviewer:

- the chapter or lab file,
- the lab script or config templates,
- the relevant transcript,
- the metadata block with tested environment and expected state,
- source IDs and research notes,
- `docs/safety.md`,
- `docs/authoring-templates/internet-readiness-standard.md`,
- issue acceptance criteria.

Ask the reviewer to focus on correctness, safety boundaries, stale assumptions, untested commands, lab-only shortcuts, and whether the stated verification proves the intended claim.

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

Also review for Internet readiness:
- whether the chapter reduces or increases false confidence,
- whether lab-only behavior is clearly labeled,
- whether packet movement, service behavior, routing control plane, and policy are separated,
- whether real-network gaps are named instead of hidden,
- whether the reader would still be lost at the DN42 or public-routing boundary.

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

- beginner reviewer date,
- technical reviewer date when applicable,
- reviewed files,
- accepted findings,
- deferred findings and linked issues,
- rejected findings with reasons.

For now, use existing labels such as `chapter`, `experiment`, `conceptual`, and `v0.1`. If the process starts getting missed, add a `needs-beginner-review` label later.

## Done Criteria for Chapter and Lab Issues

A chapter or lab issue is not done until:

- the draft follows the relevant authoring template,
- the metadata block is complete,
- the Internet-readiness standard has been considered,
- `docs/reader-knowledge.md` is updated when new concepts are introduced,
- a beginner review has been run or explicitly deferred,
- technical review has been run or explicitly deferred when required,
- accepted review findings have been addressed,
- deferred review findings have follow-up issues or clear notes,
- normal verification commands pass.
