#!/usr/bin/osascript

# Number of spaces you have
set spaceCount to 6
set picture1 to POSIX file "/Library/Desktop Pictures/2019Tesla/3840x2160_MX.jpg"
set picture2 to POSIX file "/Library/Desktop Pictures/2019Tesla/3840x2160_TE.jpg"
set picture3 to POSIX file "/Library/Desktop Pictures/2019Tesla/3840x2160_M3.jpg"
set pictureList to { picture1, picture2, picture3 }

# This was supposed to count the spaces setup in system preferences, but it's not working

# tell application "System Preferences"
#     reveal anchor "shortcutsTab" of pane id "com.apple.preference.keyboard"
#     tell application "System Events" to tell window "Keyboard" of process "System Preferences"
#         set spaceCount to count (UI elements of rows of outline 1 of scroll area 2 of splitter group 1 of tab group 1 whose name begins with "Switch to Desktop")
#     end tell
#     quit
# end tell

# Sets the background on every desktop on every space.  (Requires ^# keybaord shortcuts are enabled to switch desktops)
tell application "System Events"
  repeat with space from 1 to spaceCount
    key code 18 + space - 1 using control down ## move right
    delay 1
    repeat with i from 1 to length of pictureList
      set pictureFile to item i of pictureList
      tell desktop i
        set picture rotation to 0
        set change interval to 0
        set random order to false
        set picture to pictureFile
      end tell
    end repeat
  end repeat
end tell
