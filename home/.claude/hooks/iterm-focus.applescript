-- Bring a specific iTerm2 session to the front by its session id (GUID).
-- Usage: osascript iterm-focus.applescript <session-guid>
-- The GUID is the part of $ITERM_SESSION_ID after the colon.
on run argv
	if (count of argv) is 0 then return
	set theID to item 1 of argv
	tell application "iTerm2"
		activate
		repeat with w in windows
			repeat with t in tabs of w
				repeat with s in sessions of t
					if (id of s) is theID then
						select w
						select t
						select s
					end if
				end repeat
			end repeat
		end repeat
	end tell
end run
