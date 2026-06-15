# Cella

macOS menu bar app that shows battery percentage and time remaining until discharge or full charge, updated in real time.

## Stack

- Swift + SwiftUI — UI and app lifecycle
- IOKit — battery data (charge level, time remaining, charging state)

## Running

```
swift run
```

The app appears as a battery icon in the macOS menu bar. Click it to open the popover.

## Structure

```
Package.swift
Sources/Cella/
  CellaApp.swift   — @main entry point, MenuBarExtra scene
```

## Status

Minimal skeleton. Battery icon appears in the menu bar, popover shows a placeholder text. Battery logic not yet implemented.
