on run argv
  set targetPID to item 1 of argv as integer
  tell application "System Events" to set frontmost of first application process whose unix id is targetPID to true
end run
