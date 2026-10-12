# Display Particles

A calm storm of drifting particles over your desktop, designed to quiet a busy developer mind. It features sand, snow, ash, fire, rain, leaves, or your system theme colors, complete with an auto mode that changes the weather by itself.

It includes both a full-screen click-through desktop overlay and a bar widget with a control panel.

## Features

- **Multiple Storm Types**: Choose from System colors, Sand, Snow, Ash, Fire, Leaves, or Rain, each with custom palettes and physics.

- **Dynamic Shapes & Sizes**: Render particles as Dots, Streaks, Flakes, Shards, or Pixels in Small, Medium, or Large sizes.

- **Power & Density Controls**: Adjust the wind speed and intensity (Calm, Moderate, Intense) and particle density (Min, Avg, Max).

- **Intelligent Auto Mode**: Let auto mode independently cycle through storm types, shapes, powers, and densities over time, creating a living, changing atmosphere.

- **Desktop Overlay**: Smooth, multi-monitor particle simulation running in the background with zero input interception (`mask: Region {}`) so all clicks pass through to your apps.

- **Bar Widget Indicator**: A subtle status light on your top bar that reflects the current weather and blinks faster during intense storms.

## Install

Requires Omarchy 4 ("Quattro") or later, which uses the Quickshell-based shell.

```sh
omarchy plugin add https://github.com/soham3301/display-particles.git --enable

```

The widget starts in the right section of the bar. Move it with:

```sh
omarchy bar move io.github.soham3301.display-particles --section right

```

## Settings & Control

Click the bar widget to open the control panel popup, where you can toggle the storm on/off and customize weather presets. You can also control it via the shell command line:

```sh
omarchy-shell shell summon io.github.soham3301.display-particles '{"stormType":"snow","power":"intense"}'

```

Settings are saved automatically to your XDG state directory: `~/.local/state/display-particles/settings.json`.

## How it works

- `BarWidget.qml` provides the top bar indicator and manages panel popups.

- `Overlay.qml` creates click-through layers across all connected screens.

- `Storm.qml` handles the core particle physics simulation, wind forces, gust fronts, and turbulence.

- `Store.qml` synchronizes state between the control panel and overlay via local JSON files without IPC overhead.

- `Auto.qml` drives autonomous weather transitions when sections are set to auto.

- `Model.js` acts as the single source of truth for options, color palettes, and physics constants.

## Security

Plugins run unsandboxed inside the long-lived `omarchy-shell` process with your user permissions. This plugin only reads and writes local settings files inside your XDG state directory (`~/.local/state/display-particles`) and runs standard QML/Qt Quick visual components.

## Update and remove

```sh
omarchy plugin update
omarchy plugin remove io.github.soham3301.display-particles

```

## License

MIT. See [LICENSE](LICENSE)[cite: 7, 8].
