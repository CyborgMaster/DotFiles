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
#
# Suppressing "still settling" pings: when notification_type is "idle_prompt"
# (this session's turn ended and it's waiting on you), we first check whether
# any session for this same project (this one, or a background agent spawned
# via /background) still has a live child process - a Monitor poll loop, a
# `run_in_background` Bash task, etc. If so, we skip the alert rather than
# paging you for a state that isn't final yet.
#
# Session discovery uses `claude agents --json --cwd <path>` - the documented,
# scriptable CLI interface (see `claude agents --help`), not undocumented
# internals. But we still verify liveness ourselves via `pgrep -P <pid>`
# rather than trusting that command's own status/state fields, because we hit
# real staleness trying two "more proper" app-level signals first:
#   - ~/.claude/jobs/<jobId>/state.json tracks a background agent's own
#     fan-out work (`inFlight`/`fan`, the same data the footer's "N shell"
#     reads) - but its worker process gets recycled into a `bg-spare` pool
#     once free, and inFlight can be left stuck nonzero forever after the
#     underlying work actually finished, with nothing left to correct it.
#   - Checking the worker's current pid/command line (e.g. for "bg-spare")
#     to "verify" that seemed reasonable, but produced false NEGATIVES: a
#     background Bash task runs detached from the top-level process that
#     spawned it, so the worker can be sitting idle-as-spare while its own
#     backgrounded shell is still genuinely running.
# A session's own live children are ground truth for "is there still
# something running here" in both directions, and cover the interactive
# case too (a Monitor/background Bash task started directly in an
# interactive session, no separate spawned agent - this is exactly the
# ENG-462 case that motivated this approach). We haven't confirmed whether
# `claude agents --json`'s own status/state fields are immune to the same
# staleness as the internal file was, so we don't rely on them for this.
#
# Other notification types (permission prompts, auth, elicitation, etc.) are
# always actionable right now regardless of what else is running, so they
# skip this check and fire immediately.

# Hooks can run with a minimal PATH; make sure Homebrew tools (jq,
# terminal-notifier), the `claude` CLI itself, and the system tools are all
# findable.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

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
notification_type=$(printf '%s' "$input" | jq -r '.notification_type // ""')

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

# If this is just "your turn ended, waiting on input" (idle_prompt) and this
# session (or a sibling for the same project) has a live child process, skip
# the alert - it's not settled yet, whatever's running will finish and
# re-trigger this hook on its own.
if [ "$notification_type" = "idle_prompt" ] && [ -n "$cwd" ]; then
	agents_json=$(claude agents --json --cwd "$cwd" 2>/dev/null)
	# --cwd matches "under <path>" (prefix), not exact - a session sitting in a
	# broad directory (e.g. plain $HOME) would otherwise get every unrelated
	# session anywhere below it lumped in. Re-filter to exact cwd equality.
	for sib_pid in $(printf '%s' "$agents_json" | jq -r --arg cwd "$cwd" '.[] | select(.cwd == $cwd) | .pid // empty' 2>/dev/null); do
		# Ignore Claude Code's own housekeeping children: `caffeinate` (a
		# keep-awake companion spawned whenever a session does real work,
		# unrelated to whether there's an in-flight task) and any nested
		# `claude` process itself (daemon/bg-spare management). We match only
		# on the executable (first word of the command), not the whole
		# command line: a genuine backgrounded shell task's full command
		# routinely CONTAINS "claude" too (it sources
		# ~/.claude/shell-snapshots/... and writes to a /tmp/claude-*-cwd
		# file), so a substring match over the whole line false-positives on
		# real work. `pgrep -l`'s short name is just the version string like
		# "2.1.212" here, not "claude", so we check the resolved executable
		# path instead - which can be the versioned binary
		# (~/.local/share/claude/versions/X.Y.Z), the `~/.local/bin/claude`
		# wrapper, or a bare `claude` if PATH-resolved.
		for child in $(pgrep -P "$sib_pid" 2>/dev/null); do
			cmd=$(ps -o command= -p "$child" 2>/dev/null)
			[ -z "$cmd" ] && continue
			exe="${cmd%% *}"
			case "$exe" in
				claude|*/claude|*/claude/versions/*|caffeinate|*/caffeinate) continue ;;
			esac
			printf '%s\n' "Claude: $project | $label | suppressed (pid $sib_pid has live child pid $child)" >> "$LOG"
			exit 0
		done
	done

	# Second, independent check: a `fork` subagent (Agent tool,
	# subagent_type "fork") runs in-process, sharing the model/session
	# infrastructure rather than spawning an OS child - it never shows up in
	# claude agents --json or via pgrep, so the check above is blind to it.
	# Dispatching a fork intentionally ends the current turn (that's the
	# point - keep chatting while it churns in the background), so idle_prompt
	# fires whether or not the fork has actually returned yet. We detect a
	# still-running fork directly from the transcript instead: every fork's
	# Agent tool_use gets a matching tool_result appended once it completes,
	# so a tool_use with no later tool_result means it's still in flight.
	if [ -n "$transcript" ] && [ -f "$transcript" ]; then
		fork_ids=$(tr -d '\000' < "$transcript" 2>/dev/null \
			| grep -F '"subagent_type":"fork"' \
			| jq -r '.message.content[]? | select(.type=="tool_use" and .name=="Agent" and .input.subagent_type=="fork") | .id' 2>/dev/null)
		if [ -n "$fork_ids" ]; then
			result_ids=$(tr -d '\000' < "$transcript" 2>/dev/null \
				| grep -F '"tool_result"' \
				| jq -r '.message.content[]? | select(.type=="tool_result") | .tool_use_id' 2>/dev/null)
			for fid in $fork_ids; do
				if ! printf '%s\n' "$result_ids" | grep -qF "$fid"; then
					printf '%s\n' "Claude: $project | $label | suppressed (fork $fid still in flight)" >> "$LOG"
					exit 0
				fi
			done
		fi
	fi
fi

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
