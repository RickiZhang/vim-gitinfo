let g:gitinfo_enable = 0
let s:vim_start_up = 0
let s:is_in_normal = 1
let s:current_line = -1
let s:is_handling_move = 0
" infoboard plugin info
let s:infoboard_agent = v:null
let s:all_line_commit_info = []
let s:last_line_commit_info = ""

function! s:ShowLastCommitter()
    " get the last commiter info of the current line
    " let l:committer_info = GetLastCommitterInfo()
    let l:current_line = line('.')
    if l:current_line > len(s:all_line_commit_info)
        echom 'current lineno:' . l:current_line . ' is greater than commit info cache size:' . len(s:all_line_commit_info)
        return
    endif
    "let l:start_time = reltime()
    let l:committer_info = s:all_line_commit_info[l:current_line - 1]
    let l:message = "last commit: [" . l:committer_info.committer .  "] [" . l:committer_info.date. "] [" . l:committer_info.message . "]"
    if len(s:last_line_commit_info) == 0 || s:last_line_commit_info != l:message
        call s:infoboard_agent.SetLine('gitinfo', 1, l:message)
        let s:last_line_commit_info = l:message
    endif
    " echom 'show last commiter elapsed time:' . reltimestr(reltime(l:start_time))
endfunction

" get commit info of all current buffer lines
function! s:onBufEnter()
    if g:gitinfo_enable == 0
        return
    endif
    let l:filename = bufname(bufnr())
    " buffer must be associated with a file that is tracked by git
    if !filereadable(l:filename) || isdirectory(l:filename)
        echom 'onBufEnter: ' . l:filename . ' not a readable file'
        return
    endif
    if len(system('git ls-files ' . l:filename)) == 0
        echom 'onBufEnter: ' . l:filename . ' not tracked by git'
        return
    endif 
    let l:start_time = reltime()
    " precompute all the line commit infos
    let s:all_line_commit_info = []
    let l:raw_line_commit_info = split(system('git blame --date=relative ' . l:filename), '\n')
    let l:commit_log_list = system('git log --format=format:"%H %s"')
    for raw_commit_info in l:raw_line_commit_info
        let l:committer = matchstr(raw_commit_info, '(\zs\S\+\ze\s')
        let l:time_since_commit = matchstr(raw_commit_info, '(\S\+\s\+\zs.\+ago\ze')
        let l:commit_hash = matchstr(raw_commit_info, '^\zs\S\+\ze\s')
        let l:commit_message = matchstr(l:commit_log_list, l:commit_hash . '\S*\s\+\zs[^\n]*\ze')
        let l:line_commit_info = { 'committer': l:committer, 'date': l:time_since_commit, 'message': l:commit_message }
        call add(s:all_line_commit_info, l:line_commit_info)
    endfor
    echom 'update all_line_commit_info elapsed time:' . reltimestr(reltime(l:start_time))
endfunction

function! s:CursorMoved()
    if s:vim_start_up == 0
        let s:vim_start_up = 1
        return
    endif
    if g:gitinfo_enable == 0 || s:is_in_normal == 0 || s:infoboard_agent is# v:null || s:is_handling_move == 1
        return 
    endif
    let l:bufname = bufname(bufnr())
    if !filereadable(getcwd() . '/' . l:bufname) || isdirectory(getcwd() . '/' . l:bufname)
        return
    endif
    if s:current_line == line('.')
        return
    endif
    let s:is_handling_move = 1
    let s:current_line = line('.')
    call s:ShowLastCommitter()
    let s:is_handling_move = 0
endfunction

function! s:ToggleGitInfo()
    if !isdirectory(getcwd() . '/.git')
        return
    endif
    if g:gitinfo_enable == 1
        let g:gitinfo_enable = 0
    else
        let g:gitinfo_enable = 1
        let s:current_line = -1
        call s:onBufEnter()
        call s:CursorMoved()
    endif
endfunction

function! s:RegisterToInfoboard()
    if !exists('g:loaded_infoboard') || g:loaded_infoboard == 0
        return
    endif
    let s:infoboard_agent = GetInfoboardAgent()
    call s:infoboard_agent.RegisterInfoSource('gitinfo')
    noautocmd call s:infoboard_agent.SetLine('gitinfo', 1, ' ')
endfunction

command! ToggleGitInfo call s:ToggleGitInfo()

autocmd VimEnter * call s:RegisterToInfoboard()
autocmd CursorMoved * call s:CursorMoved()
autocmd BufEnter * call s:onBufEnter()
autocmd InsertEnter * let s:is_in_normal = 0
autocmd CmdlineEnter * let s:is_in_normal = 0
autocmd InsertLeave * let s:is_in_normal = 1
autocmd CmdlineLeave * let s:is_in_normal = 1
