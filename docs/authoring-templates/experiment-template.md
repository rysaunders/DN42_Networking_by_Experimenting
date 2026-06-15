# Experiment Template

## Reader Starting Point

What does the reader need to know before this experiment? List any idea that must be explained first.

## Question

What will this experiment prove or disprove?

## Hypothesis

If the relevant network state is correct, what should happen?

## New Terms

Define every new term introduced by the experiment.

- `term`: plain-language definition and concrete example.

## Mental Model

Describe the smallest useful model for the experiment. Include an ASCII or Mermaid diagram for topology, packet path, or state transitions.

## Safety Boundaries

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

## Predict Before Running

Ask the reader to predict what should happen before at least one route lookup, packet test, or service check.

## Expected Observations

List the specific command outputs or state transitions expected.

For every important output, explain why it happened.

## What Changed

Explain the before/after state in the kernel, daemon, registry, or service being tested.

## Troubleshooting Branches

- If there is no route, inspect addressing and route tables.
- If there is a route but no packet flow, inspect forwarding and firewalls.
- If control-plane state exists but kernel state does not, inspect route export.

## Connection to Later Chapters

Map the lab result to later DN42 work. Identify what this experiment teaches that WireGuard, BIRD, registry objects, or DNS will reuse.

## Evidence to Capture

- Commands.
- Exit codes.
- Relevant stdout and stderr.
- Environment metadata.

## References

- `source-id`: short reason used.
