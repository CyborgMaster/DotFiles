#!/usr/bin/env bash
#
# Claude Code "Notification" hook.
#
# Fires whenever a Claude Code session is waiting on you (permission prompts,
# idle-input prompts, etc.). Claude Code sends the event payload as JSON on
# stdin. This script:
#
#   1. Nudges the terminal - iTerm "request attention" + a bell. These ride the
#      terminal stream, so they reach your local iTerm even over SSH.
#   2. Then, depending on where the session is actually running:
#        - Local machine: plays a sound (afplay) and posts a desktop banner via
#          terminal-notifier (falls back to osascript). On iTerm, clicking the
#          banner jumps to the *exact* tab that is waiting.
#        - Remote dev box (over SSH): emits an iTerm OSC-9 notification, which
#          travels back through SSH and is shown by the iTerm on your local
#          machine. (terminal-notifier / osascript / afplay would only act on
#          the dev box, where you can't see or hear them.)
#
# Wired up from ~/.claude/settings.json:
#     "hooks": { "Notification": [ { "matcher": "", "hooks": [
#         { "type": "command", "command": "bash \"$HOME/.claude/hooks/notify.sh\"" }
#     ] } ] }
#
# This file lives in the dotfiles castle and is symlinked to
# ~/.claude/hooks/notify.sh, so configs reference the ~/.claude path, never the
# repo path.

# Hooks can run with a minimal PATH; make sure Homebrew tools (jq,
# terminal-notifier) and the system tools are all findable.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# ---- config ----------------------------------------------------------------
SOUND="/System/Library/Sounds/Glass.aiff"   # any file in /System/Library/Sounds
MAX_TITLE_CHARS=48                           # how much of the session title to show
FOCUS_SCRIPT="$HOME/.claude/hooks/iterm-focus.applescript"
LOG="/tmp/claude-notifications.log"
# ----------------------------------------------------------------------------

# Read the JSON payload from stdin.
input=$(cat)

# Pull out the fields we use.
message=$(printf '%s' "$input"   | jq -r '.message // "Needs your attention"' | head -c 200)
cwd=$(printf '%s' "$input"       | jq -r '.cwd // ""')
session_id=$(printf '%s' "$input"| jq -r '.session_id // ""')
transcript=$(printf '%s' "$input"| jq -r '.transcript_path // ""')

# Project = the folder the session runs in.
project=$(basename "$cwd" 2>/dev/null)
case "$project" in ""|.) project="Claude Code";; esac

# Session label: use the session title from the transcript, truncated to
# MAX_TITLE_CHARS. Two kinds of title line can appear:
#   - "custom-title" (field "customTitle") : a name you set yourself with /name
#   - "ai-title"     (field "aiTitle")     : Claude's auto-generated title
# Take the most recent line of either kind so an explicit /name wins, and read
# whichever field that line carries. Brand-new sessions have no title yet, so
# fall back to a short session id.
label=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
	# `tr -d '\000'` strips stray NUL bytes: transcripts can contain them (e.g.
	# in tool output), and a single NUL makes grep treat the whole file as
	# binary and emit nothing, which silently dropped the title.
	label=$(tr -d '\000' < "$transcript" 2>/dev/null \
		| grep -E '"type":"(custom-title|ai-title)"' \
		| tail -1 \
		| jq -r '.customTitle // .aiTitle // empty' 2>/dev/null)
fi
if [ -n "$label" ]; then
	label=$(printf '%s' "$label" | cut -c1-"$MAX_TITLE_CHARS")
else
	label="session $(printf '%s' "$session_id" | cut -c1-8)"
fi

# Are we running on a remote dev box (over SSH) or on the local machine?
# The local-machine notifiers (terminal-notifier / osascript / afplay) all act
# on the machine they run on, so over SSH they'd fire on the dev box where you
# can't see them. SSH_* are set by sshd in the remote session's environment.
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CLIENT" ]; then
	remote=1
else
	remote=0
fi

# tmux passthrough wrapper for terminal escape sequences (DCS) when in tmux.
if [ -n "$TMUX" ]; then pre='\033Ptmux;\033'; suf='\033\\'; else pre=''; suf=''; fi

# 1. Attention nudge + bell. These travel down the terminal stream, so they
#    reach the local iTerm whether the session is local or remote. The bell is
#    also the audible cue when remote (afplay would only beep on the dev box).
printf "${pre}\033]1337;RequestAttention=once\a${suf}" > /dev/tty 2>/dev/null
printf '\a' > /dev/tty 2>/dev/null

# 2. The visible notification.
if [ "$remote" -eq 1 ]; then
	# --- Remote (SSH): iTerm OSC-9 notification, rendered by your local iTerm. ---
	#     One string only; we pack project + session title + message into it.
	printf "${pre}\033]9;%s\a${suf}" "Claude: $project | $label | $message" > /dev/tty 2>/dev/null
else
	# --- Local: audible cue + desktop banner (with click-to-focus on iTerm). ---
	afplay "$SOUND" >/dev/null 2>&1 &   # backgrounded so it never delays the banner

	guid="${ITERM_SESSION_ID##*:}"      # iTerm session GUID (used for click-to-focus)

	# Map the current terminal to its bundle id (for foregrounding non-iTerm apps).
	case "$TERM_PROGRAM" in
		iTerm.app)      bundle="com.googlecode.iterm2" ;;
		Apple_Terminal) bundle="com.apple.Terminal" ;;
		ghostty)        bundle="com.mitchellh.ghostty" ;;
		WezTerm)        bundle="com.github.wez.wezterm" ;;
		vscode)         bundle="com.microsoft.VSCode" ;;
		*)              bundle="" ;;
	esac

	if command -v terminal-notifier >/dev/null 2>&1; then
		set -- -title "Claude: $project" -subtitle "$label" -message "$message" -group "claude-$session_id"
		if [ "$TERM_PROGRAM" = "iTerm.app" ] && [ -n "$guid" ] && [ -f "$FOCUS_SCRIPT" ]; then
			# Click the banner -> jump straight to the waiting iTerm tab.
			set -- "$@" -execute "osascript '$FOCUS_SCRIPT' '$guid'"
		elif [ -n "$bundle" ]; then
			# Other terminals: click just brings the app forward.
			set -- "$@" -activate "$bundle"
		fi
		terminal-notifier "$@" >/dev/null 2>&1
	else
		# terminal-notifier not installed: plain banner via osascript.
		osascript -e "display notification \"$message\" with title \"Claude: $project\" subtitle \"$label\"" >/dev/null 2>&1
	fi
fi

# Small debug log.
printf '%s\n' "Claude: $project | $label | $message" >> "$LOG"
exit 0
