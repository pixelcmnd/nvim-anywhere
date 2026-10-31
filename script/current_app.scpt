-- Use the process ID, avoiding application-name quoting and ambiguity.
tell application "System Events" to return unix id of first application process whose frontmost is true
