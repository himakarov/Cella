# Cella

macOS menu bar app that shows battery percentage and time remaining until discharge or full charge, updated in real time.

## Stack

- Swift + SwiftUI — UI and app lifecycle
- IOKit.ps — battery data via `IOPSCopyPowerSourcesInfo` / `IOPSCopyPowerSourcesList` / `IOPSGetPowerSourceDescription`

## Running

```
swift run
```

The app appears in the macOS menu bar. Click the icon to open the popover.

## Structure

```
Package.swift
Sources/Cella/
  CellaApp.swift       — @main entry point, MenuBarExtra scene, BatteryPopover view
  BatteryMonitor.swift — ObservableObject: reads IOKit power sources, publishes
                         percentage + BatteryStatus enum,
                         live-updates via IOPSNotificationCreateRunLoopSource + 30s Timer
```

## Battery status model

`BatteryStatus` enum (four explicit states):

| Case | Condition | `kIOPSIsChargingKey` | `Power Source State` | `kIOPSIsChargedKey` |
|------|-----------|----------------------|----------------------|---------------------|
| `.onBattery(minutesToEmpty:)` | On battery | 0 | Battery | 0 |
| `.charging(minutesToFull:)` | Actively charging | 1 | AC Power | 0 |
| `.chargeLimited` | AC connected, charge limit reached | 0 | AC Power | 0 |
| `.charged` | Fully charged | 0 | AC Power | 1 |

Key insight: use `kIOPSIsChargingKey` (not `Power Source State`) to distinguish
`.charging` from `.chargeLimited` — both have `AC Power` state but the system stops
current flow at the charge limit (e.g. 80%), so `Is Charging = 0`.

## Menu bar label format

| State | Label | Icon |
|-------|-------|------|
| `.onBattery(nil)` | `80% · …` | battery.N |
| `.onBattery(mins)` | `80% · 3:42` | battery.N |
| `.charging(nil)` | `80% · Заряжается` | bolt.fill |
| `.charging(mins)` | `80% · 1:30` | bolt.fill |
| `.chargeLimited` | `80%` | battery.N |
| `.charged` | `100% · Заряжено` | battery.100 |

## Status

Battery monitoring fully implemented with correct four-state model. Charge limit
state correctly detected and displayed without misleading time estimates.
