#!/bin/zsh
#
# notify-on-idle — macOS desktop notification when Claude Code goes idle.
#
# Label precedence:  $CLAUDE_LABEL  >  iTerm tab/session name  >  project dir
# Configurable via env:
#   CLAUDE_LABEL          force a specific label (overrides everything)
#   CLAUDE_NOTIFY_TITLE   notification title  (default: "Claude Code")
#   CLAUDE_NOTIFY_SOUND   notification sound  (default: "Glass"; empty = silent)
#
# The notification is sent via JXA (JavaScript for Automation) rather than
# plain AppleScript: AppleScript's `system attribute` decodes environment
# variables as Mac Roman and garbles any UTF-8 (em dashes, accents, emoji).
# JXA reads the env through Foundation and preserves UTF-8 exactly.

# macOS only — no-op cleanly on other platforms.
command -v osascript >/dev/null 2>&1 || exit 0

# --- project name from the hook's stdin cwd (fallback: $PWD) ---
input="$(cat)"
cwd=""
if command -v jq >/dev/null 2>&1; then
  cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
fi
[[ -z "$cwd" ]] && cwd="$PWD"
project="${cwd##*/}"

# --- iTerm tab/session name, if running inside iTerm ---
tabname=""
if [[ -n "$ITERM_SESSION_ID" ]]; then
  uuid="${ITERM_SESSION_ID#*:}"
  raw="$(osascript 2>/dev/null <<OSA
tell application "iTerm2"
  repeat with w in windows
    repeat with t in tabs of w
      repeat with s in sessions of t
        if id of s is "$uuid" then return name of s
      end repeat
    end repeat
  end repeat
end tell
OSA
)"
  # Strip Claude's leading braille "spinner" glyph (U+2800..U+28FF) and
  # surrounding whitespace; also trim trailing whitespace.
  tabname="$(printf '%s' "$raw" | perl -CSDA -pe 's/^[\x{2800}-\x{28FF}\s]+//; s/\s+$//' 2>/dev/null)"
fi

# --- choose the most readable label ---
label="$CLAUDE_LABEL"
[[ -z "$label" ]] && label="$tabname"
[[ -z "$label" ]] && label="$project"

# --- notify (JXA → correct UTF-8) ---
NOTIFICATION_TEXT="Finished — $label" \
NOTIFICATION_TITLE="${CLAUDE_NOTIFY_TITLE:-Claude Code}" \
NOTIFICATION_SOUND="${CLAUDE_NOTIFY_SOUND-Glass}" \
  osascript -l JavaScript -e '
    ObjC.import("Foundation");
    function envv(k){ var v = $.NSProcessInfo.processInfo.environment.objectForKey(k); return v.isNil() ? null : ObjC.unwrap(v); }
    var app = Application.currentApplication();
    app.includeStandardAdditions = true;
    var opts = { withTitle: envv("NOTIFICATION_TITLE") || "Claude Code" };
    var snd = envv("NOTIFICATION_SOUND");
    if (snd) opts.soundName = snd;
    app.displayNotification(envv("NOTIFICATION_TEXT") || "", opts);
  '
