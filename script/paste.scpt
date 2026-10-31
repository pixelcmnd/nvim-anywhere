on run argv
  set targetPID to item 1 of argv as integer
  tell application "System Events"
    if unix id of first application process whose frontmost is true is not targetPID then error "Target application is not frontmost"
    keystroke "v" using command down
  end tell
end run
