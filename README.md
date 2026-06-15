# Cella

A tiny native macOS menu bar app that shows battery percentage and time remaining until discharge or full charge — updated in real time.

**Features:**
- Battery percentage, time remaining, and status icon in the menu bar
- Four states: on battery, charging, charge-limited, fully charged
- Battery health info (capacity %, cycle count)
- Configurable menu bar display (icon / percentage / time)
- English and Russian interface
- Launch at login

## Install

Paste this into Terminal — no Xcode required:

```bash
curl -fsSL https://raw.githubusercontent.com/himakarov/Cella/main/install.sh | bash
```

On first launch macOS may show a security warning. If it does, run:

```bash
xattr -cr /Applications/Cella.app && open /Applications/Cella.app
```

## Update

Same command as install — it stops the running app, downloads the latest version, and restarts it:

```bash
curl -fsSL https://raw.githubusercontent.com/himakarov/Cella/main/install.sh | bash
```

## Build from source

Requires Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/himakarov/Cella.git
cd Cella
./redeploy.sh
```

## Requirements

- macOS 13 Ventura or later
