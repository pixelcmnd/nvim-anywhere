" Session-local cancellation; this file is sourced after the user's vimrc.
command! NvimAnywhereCancel call writefile([], $NVIM_ANYWHERE_CANCEL_FILE) | cquit
command! VimAnywhereCancel NvimAnywhereCancel
let s:forced_quit = 0
let s:quitting = 0
augroup nvim_anywhere_session
  autocmd!
  autocmd CmdlineLeave : let s:forced_quit = !get(v:event, 'abort', 0) && getcmdline() =~# '^\s*\%(q\|quit\|qa\|qall\)!\s*$'
  autocmd QuitPre * let s:quitting = s:forced_quit
  autocmd WinEnter * let s:quitting = 0
  autocmd VimLeavePre * if s:quitting | call writefile([], $NVIM_ANYWHERE_CANCEL_FILE) | endif
augroup END
