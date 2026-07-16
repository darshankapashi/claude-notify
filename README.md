# claude-notify

A [Claude Code](https://code.claude.com) plugin marketplace with one plugin: **notify-on-idle**.

## notify-on-idle

Pops a macOS desktop notification when Claude Code finishes a turn and is
waiting for your next prompt. The notification is labeled so you can tell
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

> **Note:** if you already have an equivalent `Notification` hook in your
> `settings.json`, remove it after enabling the plugin, otherwise you'll get
> two notifications.

### Configuration (optional env vars)

| Variable              | Default        | Effect                                            |
|-----------------------|----------------|---------------------------------------------------|
| `CLAUDE_LABEL`        | —              | Force a fixed label (overrides tab/project)       |
| `CLAUDE_NOTIFY_TITLE` | `Claude Code`  | Notification title                                |
| `CLAUDE_NOTIFY_SOUND` | `Glass`        | Notification sound name (set empty for silent)    |

Example — a stable label for a given window regardless of what Claude does:

```bash
CLAUDE_LABEL="Backend" claude
```

### How it works

- Hooks into the `Notification` event with matcher `idle_prompt`.
- Reads the session's `cwd` from the hook's stdin JSON for the project name.
- Queries iTerm2 (via the `ITERM_SESSION_ID` UUID) for the tab name and strips
  Claude's leading braille "spinner" glyph.
- Sends the notification through **JXA** (JavaScript for Automation) so UTF-8
  (em dashes, accents, emoji) renders correctly — plain AppleScript
  `system attribute` decodes env vars as Mac Roman and garbles them.

### Requirements

macOS. Uses only system tools (`osascript`, `perl`, `zsh`); `jq` is used if
present but not required. iTerm tab-name labeling requires iTerm2; in other
terminals it falls back to the project directory name.

## License

MIT
