# Experiment Template

## Reader Starting Point

What does the reader need to know before this experiment? List any idea that must be explained first.

Use `docs/reader-knowledge.md` as the source of truth for what prior chapters and labs have taught.

## Question

What will this experiment prove or disprove?

State how this experiment helps answer the guiding question: how does an Internet emerge from a collection of computers exchanging routes?

Apply `docs/authoring-templates/internet-readiness-standard.md`. State what this experiment does not prove about DN42, public routing, services, policy, or operations.

## Hypothesis

If the relevant network state is correct, what should happen?

## New Terms

Define every new term introduced by the experiment.

- `term`: plain-language definition and concrete example.

Update `docs/reader-knowledge.md` for every term this experiment teaches for the first time.

## Mental Model

Describe the smallest useful model for the experiment. Include an ASCII or Mermaid diagram for topology, packet path, or state transitions.

## Safety Boundaries

Use `docs/safety.md` to choose the lab safety level and required checks.

- No unintended default route.
- No unintended export.
- No persistent state without rollback.

## Procedure

1. Prepare the environment.
2. Capture baseline state.
3. Make one change.
4. Observe the result.
5. Roll back the change.

For each command, explain what state it changes before showing the command.

Experiments should be manual-first. A script can exist for repeatability and transcript capture, but the published lesson should teach the reader to build the important state directly in the shell.

## Code Block Conventions

Use code block titles for execution context and purpose:

- `Run from the root Linux shell`
- `Run inside pocket-as1`
- `Write /tmp/example.conf`
- `Expected output`

Keep command blocks, config blocks, output blocks, and interpretation separate. For generated config blocks over about 20 lines, use sparse annotations for the few lines that teach the concept under test. Avoid annotating every setup command.

## Lab State Continuity

Declare whether the experiment is standalone, dependent on a named checkpoint, or an extension of a still-running prior lab.

For now, prefer standalone experiments that rebuild their own required state and clean up afterward. This costs more commands, but it avoids hidden state and makes transcripts easier to trust.

If an experiment uses a setup helper or checkpoint script, document that the helper restores known state; do not let it replace the manual teaching path for the concept under study.

## Long-Running Processes

If the experiment starts a service or daemon:

- Prefer backgrounding it and recording a PID file under the lab temp directory.
- Capture logs to a file when those logs are part of the evidence.
- Show the command that proves the process is listening.
- Show rollback that kills the process by PID before deleting namespaces.
- Mention a second shell only as an optional workflow, not as a requirement.

## Predict Before Running

Ask the reader to predict what should happen before at least one route lookup, packet test, or service check.

## Expected Observations

List the specific command outputs or state transitions expected.

For every important output, explain why it happened.

If the experiment is intentionally repetitive or annoying, name that friction in plain language. The point is not to entertain the reader; the point is to make the learning arc visible. Say what the manual work teaches, and name the later tool or concept that will reduce the pain.

Examples:

- Writing both forward and return routes by hand is tedious. That is the pressure that makes dynamic routing useful.
- Checking every filter by hand is slow. That is why later safety patterns need to be explicit and reusable.

## What Changed

Explain the before/after state in the kernel, daemon, registry, or service being tested.

## Troubleshooting Branches

- If there is no route, inspect addressing and route tables.
- If there is a route but no packet flow, inspect forwarding and firewalls.
- If control-plane state exists but kernel state does not, inspect route export.

## Connection to Later Chapters

Map the lab result to later Pocket Internet, interconnect, or DN42 work. Identify what this experiment teaches that WireGuard, BIRD, registry objects, or DNS will reuse.

Name any real-network topic this experiment intentionally leaves out, such as DNS, TCP/UDP service behavior, firewall policy, IPv6, authorization, monitoring, or rollback.

## Evidence to Capture

- Commands.
- Exit codes.
- Relevant stdout and stderr.
- Environment metadata.
- Safety baseline and rollback verification.

## Transcript Convention

Checked-in validation transcripts live directly under `experiments/transcripts/` and are referenced by chapters.

Local script runs write to `experiments/transcripts/local/` by default. That directory is ignored so readers and maintainers can rerun labs without polluting Git status.

To intentionally regenerate a checked-in transcript, run the lab with `LAB_TRANSCRIPT_PATH` set to the exact tracked path:

```sh
LAB_TRANSCRIPT_PATH=experiments/transcripts/<lab-name>-<timestamp>.txt \
  experiments/labs/<lab-name>/run.sh
```

After regenerating a checked-in transcript, update any chapter reference that names the old transcript.

## Beginner Review

- [ ] Reviewer received this experiment, the relevant transcript, the authoring template, and `docs/reader-knowledge.md`.
- [ ] Reviewer considered the Internet-readiness standard.
- [ ] Accepted findings are addressed.
- [ ] Deferred findings have follow-up issues or notes.
- [ ] Rejected findings include a reason.

## References

- `source-id`: short reason used.
