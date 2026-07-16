# claude-notify

A [Claude Code](https://code.claude.com) plugin marketplace with one plugin: **notify-on-idle**.

## notify-on-idle

Pops a macOS desktop notification when Claude Code finishes a turn and is
waiting for your next prompt — so you can step away and get tapped on the
shoulder when it's your turn again. The notification is labeled so you can tell
*which* session finished when you have several running at once.

**Label precedence:** `$CLAUDE_LABEL` → iTerm tab/session name → project directory.

> **Claude Code**
> Finished — refactor auth middleware

### Install

From inside Claude Code:

```
/plugin marketplace add darshankapashi/claude-notify
/plugin install notify-on-idle@claude-notify
```

Then enable it from `/plugin`. No `settings.json` editing required.

> **After installing, do the one-time macOS setup below.** Without it, the
> notification is delivered silently to Notification Center (no banner, no
> sound) while you're in another app — exactly when you want to see it.

> If you already have an equivalent `Notification` hook in your `settings.json`,
> remove it after enabling the plugin, or you'll get two notifications.

### First-time setup — macOS notification permissions

The hook posts notifications via macOS's `osascript`, so they're attributed to
the **Script Editor** app. Until you allow Script Editor to show alerts (and let
it through any Focus), macOS quietly drops the banner into Notification Center
while you're away.

**The easy way — ask Claude.** In a session with this plugin installed, say:

> "Set up notify-on-idle notifications."

Claude can open the right settings panes and walk you through the toggles by
running these (they're safe, and are exactly what a human would click):

```bash
# Open System Settings → Notifications  (then find "Script Editor" in the list)
open "x-apple.systempreferences:com.apple.Notifications-Settings.extension"

# Open System Settings → Focus  (to allow Script Editor through Do Not Disturb)
open "x-apple.systempreferences:com.apple.Focus-Settings.extension"

# Fire a test notification to confirm it shows
osascript -l JavaScript -e 'var a=Application.currentApplication();a.includeStandardAdditions=true;a.displayNotification("Setup test — you should see this",{withTitle:"Claude Code",soundName:"Glass"});'
```

**What to set:**

1. **Notifications → Script Editor**
   - *Allow Notifications*: **On**
   - *Alert style*: **Alerts** (persists) or **Banners** (auto-hide)
   - *Play sound for notifications*: **On**
   - *Show in Notification Center* / *on Lock Screen*: your preference
2. **Focus / Do Not Disturb** — if you keep one on, either turn it off or add
   **Script Editor** to that Focus's **Allowed Notifications** so it breaks through.
3. **iTerm tab names** — the first time the hook looks up the tab name, macOS may
   show a one-time **Automation** prompt ("… wants to control iTerm2"). Allow it
   for tab-name labels; deny it and the label just falls back to the project name.
4. **Full-screen apps** — macOS holds banners while the frontmost app is
   full-screen, delivering them to Notification Center instead. Expect the
   notification there rather than as a banner if you switch to a full-screen app.

Then finish a turn, switch to another **windowed** app, and you should get a
banner + sound.

> Prefer a cleaner identity than "Script Editor"? Install
> [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) and set
> `CLAUDE_NOTIFY_*` — but the Script-Editor route above needs no extra software.

### Configuration (optional env vars)

| Variable              | Default        | Effect                                            |
|-----------------------|----------------|---------------------------------------------------|
| `CLAUDE_LABEL`        | —              | Force a fixed label (overrides tab/project)       |
| `CLAUDE_NOTIFY_TITLE` | `Claude Code`  | Notification title                                |
| `CLAUDE_NOTIFY_SOUND` | `Glass`        | Notification sound name (empty = silent)          |

Example — a stable label for a given window regardless of what Claude does:

```bash
CLAUDE_LABEL="Backend" claude
```

### How it works

- Hooks into the `Notification` event with matcher `idle_prompt` (fires when
  Claude finishes and is waiting for your input).
- Reads the session's `cwd` from the hook's stdin JSON for the project name.
- Queries iTerm2 (via the `ITERM_SESSION_ID` UUID) for the tab name and strips
  Claude's leading "spinner" glyph.
- Sends the notification through **JXA** (JavaScript for Automation) so UTF-8
  (em dashes, accents, emoji) renders correctly — plain AppleScript
  `system attribute` decodes env vars as Mac Roman and garbles them.

### Requirements

macOS. Uses only system tools (`osascript`, `perl`, `zsh`); `jq` is used if
present but not required. iTerm tab-name labeling requires iTerm2; in other
terminals it falls back to the project directory name.

## License

MIT
