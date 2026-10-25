# Quickshell desktop shell

The bar, panels, lock, notifications, launcher, OSD and the other pieces of the
desktop, for Sway, in [Quickshell](https://quickshell.org) (0.3, Qt 6). Entry
point: `shell.qml`.

```sh
qs -p config/quickshell/shell.qml   # run from the repo; edits reload live
qs log                              # the running shell's log
qs ipc call health list             # what's broken, and why
scripts/check.sh                    # structure checks (run before committing)
```

## Layout

```
shell.qml      lists the top-level modules; nothing else
core/          Config, Setup, Theme, Health, ModuleLoader, Icons; helpers for services
               (Action, DbusMonitor, Paths, objects.js)
services/      the logic: one singleton per area (Audio, Network, Session, …), no UI
components/    themed widgets with behaviour only (Skinned + a skin name)
modules/       the windows and panels: services wired to components, no drawing
themes/        the drawing: one folder per theme, plus glyphs/ (shared skins)
scripts/       check.sh; gen-symbols.sh (rebuilds assets/symbols.tsv); the
               services' longer shell scripts (<service>-<what>.sh)
assets/        symbol and kaomoji tables
```

Imports only go down: `core` ← `services` ← `modules`, and `core` ← `components`
← `modules`. Themes import `core`, `components` and `modules` (for `control`'s
type), never `services`. `scripts/check.sh` enforces this.

## Isolation

Nothing that breaks takes anything else down with it. A failure goes to
`Health` (`report(source, reason)` / `resolve(source)`; services use the
declarative `HealthCheck`), shows on the bar's indicator, and sends at most one
desktop alert per source every 10 minutes.

| What breaks              | What happens                                                       |
|--------------------------|--------------------------------------------------------------------|
| a module (`shell.qml`)   | `ModuleLoader` compiles it at runtime; reported, the rest runs     |
| a bar panel              | `PanelLoader` shows a stand-in in its drop                         |
| a bar widget             | `BarSlot` leaves a gap                                             |
| a theme's skin           | the shared one in `themes/glyphs` is used; reported                |
| every skin for a widget  | nothing is drawn (`Skinned.skinFailed`)                            |
| the lock or polkit skin  | `PlainLock` / `PlainPolkit`: plain Qt, a password field, Enter / Esc |
| a theme's `Spec.qml`     | the first theme is used                                            |
| `settings.json` invalid  | the last good settings stay                                        |

The plain stand-ins import only `QtQuick` and `qs.services`, so nothing a theme
or shared component breaks can reach them. Keep it that way.

## Settings: Config and Setup

- **`core/Config.qml`**: what you change now and then, from the Settings panel or
  `qs ipc call config set PATH JSON`. Stored outside the repo in
  `$XDG_STATE_HOME/quickshell/settings.json`, merged over the defaults in
  `Config.defaults`, watched and written back (atomically, with a `.bak` once per
  session). Add a setting by adding it to `defaults` (and to `SettingsPanel.items`
  if it belongs in the panel).
- **`core/Setup.qml`**: how this machine is set up, edited in the repo: per-theme
  token tweaks, bar spacing, launcher entries and terminal, calendar URL, control
  center tools, capture folders.

## Themes

A theme draws; it never decides what happens. Every themed widget is a
`Skinned` item (behaviour: properties, signals, input, timing) that loads
`themes/<theme>/<skin>.qml` and hands it itself as `control`:

```qml
// components/Lamp.qml                  // themes/cyber/Lamp.qml
Skinned {                               Rectangle {
    skin: "Lamp"                            required property C.Lamp control
    property bool on                        color: control.on ? Theme.palette.accent : …
}                                       }
```

- **Skin lookup**: the theme's own file, else `themes/glyphs/<skin>.qml`; a broken
  file falls back the same way and is reported. A theme only needs files for the
  skins it draws its own way.
- **Panels** are skinned too (`modules/<name>/<Name>Panel.qml` → `<Name>Menu`): the
  panel exposes state and functions, the skin lays it out. Keys typed into a skin's
  text field go to the panel (`Keys.onPressed: event => event.accepted =
  root.control.fieldKey(event.key, event.modifiers)`, or `TextField.keyFilter`);
  the panel decides what they do. Skins handle no other keys.
- **Tokens**: `themes/<name>/Spec.qml` has `label` and `defaults`: `palette` (roles:
  bg, bgAlt, shadow, surface, border, fg, dim, muted, off, accent, ok, warn, error),
  `font` (family, size, caps, tracking), `glow`, `motion`, `swatches`, and anything
  of the theme's own. `Setup.themes.<name>` overrides only what differs. Read them
  through `Theme` (`Theme.palette.accent`, `Theme.get("glow.opacity")`).
- **Layout hints** a Spec may set under `layout`: `sessionScreen` (the session menu
  full screen instead of a drop), `lockClose` / `lockOpen` (ms, ≤ 1000: a lock
  transition, below), and the theme's own (`drawers`, `hangers`, `behindBar`).
  `bar.height` asks for a taller bar.
- **Text** goes through `StyledText` (glow, caps, tracking from the theme). It's
  plain text unless a widget sets `textFormat`: notification and window text comes
  from outside, and Qt would otherwise load images it names.
- `components/` and `modules/` hold no styling (no hex colours, Rectangles, shapes,
  effects, letter spacing); `check.sh` lists offenders.

**Lock transitions.** With `lockClose` / `lockOpen` set, the lock screen plays on
an overlay above the live desktop while closing (an input catcher holds the
keyboard and clicks), then the session lock goes up; on unlock it plays opening
onto the desktop. The skin follows `control.phase` (`closing`, `locked`,
`opening`); the overlay's copy has `interactive: false`. Nothing is captured.
Locking for sleep skips the closing. Sway blanks the screen for a moment as the
session lock goes up, until the lock window's first frame.

## Recipes

- **Service**: `services/<Name>.qml`, `pragma Singleton`, imports only `qs.core`. Report
  failures with `HealthCheck { source; ok; reason }`. Run commands with arguments
  passed as they are (`["sh", "-c", '… "$1"', "sh", value]`), never outside text
  pasted into a command line (`Action` runs one and reports how it went;
  `DbusMonitor` watches a D-Bus name; `Paths.privateDir` is where private
  temp files go). A script longer than a line goes in
  `scripts/<service>-<what>.sh`, run as `["sh", Quickshell.shellPath("scripts/…"), args…]`,
  so shellcheck (in `check.sh`) sees it. Poll only while something shows the result. A
  service that has to run with no UI showing it (a daemon: notifications, idle,
  polkit…) is listed in `modules/daemons/Daemons.qml`, which starts it.
- **Bar widget**: `modules/bar/widgets/<Name>.qml` (a `Skinned`; one that opens a panel
  does `Panels.toggle(name)` and exposes `active`), a `BarSlot { widget: "<Name>" }`
  line in `Bar.qml`, and a skin in `themes/glyphs` (and any theme drawing it its
  own way).
- **Bar panel**: `modules/<name>/<Name>Panel.qml` (optional `property bool open`,
  `signal done` to close), a row in `Bar.qml`'s `panels` (`under`, `edge`, `blur`,
  `bindings`), the name in `Panels.names`, and its `<Name>Menu` skin
  (`check.sh` checks the two lists against each other).
- **Module** (its own window): a file under `modules/`, an import of its folder and
  a `ModuleLoader` line in `shell.qml`. Use `Display.primary` for the screen and a
  `qs-…` layer namespace.
- **Theme**: `themes/<name>/Spec.qml`, an entry in `Theme.names`, an import in
  `shell.qml`, skins for whatever it draws differently, and (optionally) your
  tweaks in `Setup.themes` (`check.sh` checks the folders, `Theme.names` and the
  imports agree).

## IPC

`qs ipc call <target> <function> [args]` (`qs ipc show` lists them):

| Target          | Functions                                                       |
|-----------------|-----------------------------------------------------------------|
| `panel`         | `toggle NAME`, `open NAME`, `close`, `current`                  |
| `session`       | `lock`, `locked`, `restart`                                     |
| `launcher`      | `search Q`, `windows`, `apps`, `list Q`                         |
| `clipboard`     | `paste N`, `symbols TAB`                                        |
| `capture`       | `screenshot`, `record`, `voice`, `stop`, `discard`, `status`    |
| `audio`         | `up`, `down`, `mute`, `set PERCENT`, `get`                      |
| `media`         | `playpause`, `next`, `previous`, `get`                          |
| `notifications` | `dnd`, `mute APP`, `clear`, `list`                              |
| `network`       | `status`, `scan`, `wifi BOOL`, `connect NAME`, `disconnect`     |
| `bluetooth`     | `status`, `power BOOL`, `scan`, `connect NAME`, `disconnect NAME` |
| `config`        | `get PATH`, `set PATH JSON`, `add PATH ITEM`, `remove PATH ITEM` |
| others          | `health list`, `tray menu APP`, `wallpaper set PATH \| get`, `idle status \| caffeinate`, `keys list`, `compose lookup TEXT`, `symbols search TAB Q \| refresh`, `updates status \| check`, `polkit status \| cancel`, `privacy status`, `events status` |

Panels: session, calendar, launcher, network, bluetooth, audio, notifications,
control, settings, keys, clipboard, compose.

## Sway

- Start it with `exec_always qs -n`. It replaces swayidle (idle lock and screen
  off: `Config.idle`), swaylock (ext-session-lock, PAM `login` stack), the polkit
  agent and the notification daemon (it stops dunst if that holds the name).
- Layer namespaces, for rules: `qs-bar` (bar and drops), `qs-wallpaper`,
  `qs-notifications`, `qs-osd`, `qs-clipboard`, `qs-compose`, `qs-session`,
  `qs-polkit`, `qs-capture`, `qs-capture-prompt`, `qs-lock-transition`,
  `qs-lock-catcher`. Blur behind big drops on SwayFX: `layer_effects "qs-bar" blur
  enable`.
- The keys panel reads the binds from `swaymsg -t get_config`.
- Sleep locks first (a logind delay inhibitor holds it until the lock is up);
  `loginctl lock-session` locks too.
- Tools it calls: wl-copy, cliphist, wtype, qalc, wf-recorder, pw-record,
  udisksctl, iwctl, wpctl, busctl, gdbus, systemd-inhibit, fuser, checkupdates,
  notify-send, xdg-open, curl (calendar, login from `~/.netrc`), ncdu and nvim
  (in the terminal). cliphist, wtype, qalc, gdbus, fuser and checkupdates are
  reported to Health when missing; the recorders' absence shows in the capture
  prompt.

## Known issues

- Quickshell 0.3.2 with Qt 6.12 crashes when a theme icon loads on Qt's image
  reader thread while it loads on the GUI thread
  ([quickshell#1334](https://github.com/quickshell-mirror/quickshell/issues/1334)).
  Load icons with `IconImage` / `Image` (synchronous by default); never pass an
  `image://icon/…` source to `Canvas.loadImage` or an asynchronous `Image`.
