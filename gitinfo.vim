let g:gitinfo_enable = 0
let s:vim_start_up = 0
let s:is_in_normal = 1
let s:current_line = -1
let s:is_handling_move = 0
" infoboard plugin info
let s:infoboard_agent = v:null
let s:all_line_commit_info = []
let s:last_line_commit_info = ""
let s:is_wait_server = 0 

function! s:ShowLastCommitter()
    let l:current_line = line('.')
    if l:current_line > len(s:all_line_commit_info)
        echom "current_lineno:" . l:current_line . " greater than all commit info size:" . len(s:all_line_commit_info)
        return
    endif
    let l:committer_info = s:all_line_commit_info[l:current_line - 1]
    if len(s:last_line_commit_info) == 0 || s:last_line_commit_info != l:committer_info
        call s:infoboard_agent.SetLine('gitinfo', 1, l:committer_info)
        let s:last_line_commit_info = l:committer_info
    endif
endfunction

let s:gitinfo_server_job = v:null

function! s:OnGitInfoServerMsg(channel, msg)
    if a:msg == ""
        let s:is_wait_server = 0
        noautocmd call s:ShowLastCommitter()
    else
        call add(s:all_line_commit_info, a:msg)
    endif
endfunction

function! s:OnGitInfoServerErr(channel, msg)
    echom "gitinfo error: " . a:msg
endfunction

function! s:OnGitInfoServerExit(job, status)
    call job_stop(s:gitinfo_server_job)
    let s:gitinfo_server_job = v:null
    let s:last_line_commit_info = ""
    let s:all_line_commit_info = []
    let s:is_wait_server = 0
    echom "gitinfo server exit"
endfunction

function! s:LaunchGitInfoServer()
    let s:gitinfo_server_job = job_start(['lua', $HOME . '/.vim/plugin/gitinfo/gitinfo_server.lua'], {
                \ 'out_cb': function('s:OnGitInfoServerMsg'),
                \ 'err_cb': function('s:OnGitInfoServerErr'),
                \ 'exit_cb': function('s:OnGitInfoServerExit'),
                \ 'cwd': getcwd()
                \})
    if job_status(s:gitinfo_server_job) != 'run'
        echom 'failed to launch gitinfo server, status:' . job_status(s:gitinfo_server_job)
        let s:gitinfo_server_job = v:null
        return 1
    endif
    return 0
endfunction

" get commit info of all current buffer lines
function! s:onBufEnter()
    if g:gitinfo_enable == 0 || s:gitinfo_server_job is v:null
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
    call ch_sendraw(job_getchannel(s:gitinfo_server_job), l:filename . "\n")
    let s:all_line_commit_info = []
    let s:is_wait_server = 1
    let s:last_line_commit_info = ""
    call s:infoboard_agent.SetLine('gitinfo', 1, "loading git info of current line...")
endfunction

function! s:CursorMoved()
    if s:vim_start_up == 0
        let s:vim_start_up = 1
        return
    endif
    if g:gitinfo_enable == 0 || s:is_in_normal == 0 || s:infoboard_agent is v:null || s:is_handling_move == 1
        return 
    endif
    let l:bufname = bufname(bufnr())
    if !filereadable(getcwd() . '/' . l:bufname) || isdirectory(getcwd() . '/' . l:bufname)
        return
    endif
    if s:current_line == line('.')
        return
    endif
    if s:is_wait_server == 1
        return
    endif
    let s:is_handling_move = 1
    let s:current_line = line('.')
    call s:ShowLastCommitter()
    let s:is_handling_move = 0
endfunction

function! s:RegisterToInfoboard()
    if !exists('g:loaded_infoboard') || g:loaded_infoboard == 0
        return 1
    endif
    let s:infoboard_agent = GetInfoboardAgent()
    call s:infoboard_agent.RegisterInfoSource('gitinfo')
    noautocmd call s:infoboard_agent.SetLine('gitinfo', 1, ' ')
    return 0
endfunction

function! s:UnRegisterToInfoboard()
    if !exists('g:loaded_infoboard') || g:loaded_infoboard == 0
        return
    endif
    let s:infoboard_agent = GetInfoboardAgent()
    call s:infoboard_agent.UnRegisterInfoSource('gitinfo')
endfunction

function! s:ToggleGitInfo()
    if !isdirectory(getcwd() . '/.git')
        return
    endif
    if g:gitinfo_enable == 1
        if !(s:gitinfo_server_job is v:null)
            call job_stop(s:gitinfo_server_job)
        endif
        let g:gitinfo_enable = 0
        let s:gitinfo_server_job = v:null
        let s:is_wait_server = 0
        let s:last_line_commit_info = ""
        let s:all_line_commit_info = []
        call s:UnRegisterToInfoboard()
    else
        if 0 != s:LaunchGitInfoServer()
            return
        endif
        if 0 != s:RegisterToInfoboard()
            return
        endif
        let g:gitinfo_enable = 1
        let s:current_line = -1
        call s:onBufEnter()
    endif
endfunction

command! ToggleGitInfo call s:ToggleGitInfo()

autocmd CursorMoved * call s:CursorMoved()
autocmd BufEnter * call s:onBufEnter()
autocmd InsertEnter * let s:is_in_normal = 0
autocmd CmdlineEnter * let s:is_in_normal = 0
autocmd InsertLeave * let s:is_in_normal = 1
autocmd CmdlineLeave * let s:is_in_normal = 1
