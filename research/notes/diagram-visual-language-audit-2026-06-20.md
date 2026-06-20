# Diagram Visual Language Audit

Date: 2026-06-20

Issue: #58

## Summary

Part 1 now uses Mermaid as the default language for conceptual visuals: topology, packet path, before/after tunnel shape, control-plane/data-plane relationships, and troubleshooting maps.

Text topology blocks remain where they serve as compact lab inventories. Those blocks show exact namespace, interface, address, and link names that the reader compares while typing commands. They are intentionally closer to terminal notes than conceptual diagrams.

## Changes Made

- Added explicit Mermaid light/dark theme initialization.
- Added a small Mermaid stylesheet for predictable sizing and overflow.
- Added `docs/authoring-templates/diagram-conventions.md`.
- Updated chapter and experiment templates to point at the diagram convention.
- Converted the visual glossary veth-pair diagram from ASCII to Mermaid.
- Converted the underlay/overlay conceptual diagrams in the tunnel chapters from text blocks to Mermaid.

## Intentional Text Blocks

Remaining text topology blocks are allowed when they are command-adjacent lab maps, such as:

- exact `pocket-link-a a0 10.77.0.1/30` style inventories,
- exact DNS/filtering two-namespace build summaries,
- command output,
- command/config examples,
- compact reminders where a Mermaid diagram would interrupt the manual lab flow.

These should not be treated as inconsistent by default during review. A reviewer should flag them only when the block is trying to teach relationships that would be clearer as a diagram.

## Follow-Up Guidance

During the beginner review, watch for diagrams that:

- are still too dense,
- do not say what to notice,
- repeat a nearby table without adding clarity,
- are legible visually but not pedagogically useful.

During the technical review, check that diagrams do not imply impossible packet paths, reversed control/data-plane direction, or missing return paths.
