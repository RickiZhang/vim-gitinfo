function! GetLastCommitterInfo()
    let l:current_line = line('.')
    let l:file_path = expand('%:p')
    let l:blame_output = system('git blame -L ' . l:current_line . ',' . l:current_line . ' --date=relative ' . l:file_path)
    let l:committer = matchstr(l:blame_output, '(\zs\S\+\ze\s')
    let l:time_since_commit = matchstr(l:blame_output, '(\S\+\s\+\zs.\+ago\ze')
    let l:commit_hash = matchstr(l:blame_output, '^\zs\S\+\ze\s')
    let l:commit_log_list = system('git log --format=format:"%H %s"')
    let l:commit_message = matchstr(l:commit_log_list, l:commit_hash . '\S*\s\+\zs[^\n]*\ze')
    return {'committer': l:committer, 'time_since_commit': l:time_since_commit, 'commit_message': l:commit_message, 'hash': l:commit_hash}
endfunction

let g:gitinfo_enable = 0

let s:timer = -1
let s:vim_start_up = 0
let s:current_line = -1
let s:current_col = -1
let s:commit_info_displayed = 0 
let s:no_trigger_cursor_move = 0
let s:sign_id = -1
let s:undo_point = -1

highlight CommittersInfoLine ctermfg=Black guifg=Black ctermbg=Yellow guibg=Yellow
sign define CommitInfoLine linehl=CommittersInfoLine

function! s:ShowLastCommitter()
    let s:no_trigger_cursor_move = 1
    let l:committer_info = GetLastCommitterInfo()
    let l:message = "last commit: [" . l:committer_info.committer .  "] [" . l:committer_info.time_since_commit. "] [" . l:committer_info.commit_message . "]"
    " call popup_atcursor(l:message, {
    "         \ 'pos': 'botleft',
    "         \ 'wrap': 0,
    "         \ 'border': [],
    "         \ 'padding': [0, 1, 0, 1],
    "         \ 'time': 5000,
    "         \ 'zindex': 200,
    "         \ })
    let l:cur_line_after_insert = line('.') + 1
    let l:cur_col = col('.')
    
    let s:undo_point = undotree().seq_cur

    normal! 0
    noautocmd execute 'normal! O' . l:message . "\<Esc>"
    let s:sign_id = sign_place(0, '', 'CommitInfoLine', bufnr('%'), {'lnum': s:current_line, 'priority': 1000})
    call cursor(l:cur_line_after_insert, l:cur_col)
   
    let s:current_line = line('.')
    let s:current_col = col('.')
    let s:commit_info_displayed = 1
    let s:no_trigger_cursor_move = 0
endfunction

let s:remove_cnt = 0

function! s:RestoreCursor(timer_id)
    call cursor(s:current_line, s:current_col)
endfunction

function! s:RemoveCommitInfo(call_by_cursor_moved)
    if s:commit_info_displayed == 0
        return
    endif
    let s:no_trigger_cursor_move = 1
    let l:cur_line_after_delete = line('.') - 1
    let l:cur_col = col('.')

    " normal! u
    noautocmd execute 'undo ' . s:undo_point
    let s:undo_point = -1

    if s:sign_id != -1
        call sign_unplace('', {'id': s:sign_id, 'buffer': bufnr('%')})
        let s:sign_id = -1
    endif

    call cursor(l:cur_line_after_delete, l:cur_col)

    let s:current_line = line('.')
    let s:current_col = l:cur_col
    let s:commit_info_displayed = 0
    let s:no_trigger_cursor_move = 0
    if !a:call_by_cursor_moved
        call timer_start(10, function('s:RestoreCursor'))
    endif
endfunction

function! s:CheckCanTrigger()
    return g:gitinfo_enable != 0 && s:no_trigger_cursor_move == 0 && s:current_line != line('.')
endfunction

function! s:CheckCursor(timer_id)
    let l:current_line_content = getline('.')
    if !s:CheckCanTrigger() && !empty(trim(l:current_line_content))
        call s:ShowLastCommitter()
    endif
endfunction

function! s:CursorMoved()
    if !s:CheckCanTrigger()
        return 
    endif
    if s:vim_start_up == 0
        let s:vim_start_up = 1
        return
    endif
    if s:timer != -1
        call timer_stop(s:timer)
    endif
    if s:commit_info_displayed == 1
        call s:RemoveCommitInfo(1 == 1)
    endif
    let s:current_line = line('.')
    let s:current_col = col('.')
    let s:timer = timer_start(1500, function('s:CheckCursor'))
endfunction

function! s:ToggleGitInfo()
    if !isdirectory(getcwd() . '/.git')
        return
    endif
    if g:gitinfo_enable == 1
        let v:char = "xxoo"
        if s:timer != -1
            call timer_stop(s:timer)
        endif
        if s:commit_info_displayed == 1
            call s:RemoveCommitInfo(1 == 0)
        endif
        let s:timer = -1
        let s:last_pos = [-1, -1]
        let s:current_line = -1
        let s:current_col = -1
        let s:commit_info_displayed = 0
        let s:no_trigger_cursor_move = 0
        let g:gitinfo_enable = 0
    else
        let s:vim_start_up = 1
        let g:gitinfo_enable = 1
    endif
endfunction

function! s:ExitNormal()
    if s:no_trigger_cursor_move == 1
        return
    endif
    if s:timer != -1
        call timer_stop(s:timer)
    endif
    if s:commit_info_displayed == 1
        call s:RemoveCommitInfo(1 == 0)
    endif
    let s:timer = -1
    let s:commit_info_displayed = 0
endfunction

command! ToggleGitInfo call s:ToggleGitInfo()

autocmd CursorMoved * call s:CursorMoved()
autocmd InsertEnter * call s:ExitNormal()
autocmd CmdlineEnter * call s:ExitNormal()
