# Experiment Template

## Question

What will this experiment prove or disprove?

## Hypothesis

If the relevant network state is correct, what should happen?

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

## Expected Observations

List the specific command outputs or state transitions expected.

## Troubleshooting Branches

- If there is no route, inspect addressing and route tables.
- If there is a route but no packet flow, inspect forwarding and firewalls.
- If control-plane state exists but kernel state does not, inspect route export.

## Evidence to Capture

- Commands.
- Exit codes.
- Relevant stdout and stderr.
- Environment metadata.

## References

- `source-id`: short reason used.
