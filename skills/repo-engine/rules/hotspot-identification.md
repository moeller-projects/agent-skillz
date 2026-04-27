# Rule: Hotspot Identification

> Impact: medium

## Description

Highlight only the modules or workflows that materially raise change risk or leverage.

## Apply When

- Planning work in an unfamiliar repository.

## Checks

- Hotspot listed without impact or risk explanation -> flag.
- Low-signal area included while a core workflow risk is omitted -> reorder.
- `hotspots` duplicates `map` with no extra caution guidance -> rewrite.

## Anti-Pattern

Calling an area a hotspot without evidence, impact, or handling advice.
