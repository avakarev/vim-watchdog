if exists('loaded_watchdog') || !has('statusline')
    finish
endif
let loaded_watchdog = 1

autocmd BufWinEnter,WinEnter,CmdwinEnter,CursorHold,CursorHoldI,BufWritePost * call <SID>UpdateStatusLine(1, 0)
autocmd FileType * call <SID>UpdateStatusLine(1, 0)
autocmd WinLeave * call <SID>UpdateStatusLine(0, 0)
autocmd ColorScheme * call <SID>InitScheme()

function! s:InitScheme()
    " TODO: try to load new colors
    if exists('g:WATCHDOG_COLORS_LOADED')
        unlet g:WATCHDOG_COLORS_LOADED
    endif
    call s:UpdateStatusLine(1, 1)
endfunction

if exists('watchdog_himode')
    autocmd InsertEnter * call <SID>UpdateStatusLine(1, 1)
    autocmd InsertLeave * call <SID>UpdateStatusLine(1, 0)
endif

function! s:UpdateStatusLine(is_in_focus, is_insert_mode)
    let l:bufnr    = bufnr('%')
    let l:fname    = expand('%:t')
    let l:ftype    = strlen(&filetype) ? &filetype : 'none'
    let l:datetime = strftime('%Y-%m-%d %T',getftime(expand('%'))) " 10+1+8=19
    let l:scm_stat = exists('g:loaded_fugitive') ? fugitive#statusline() : ''

    let l:stl_len = 0 " Length of expanded status line

    " Group of status flags
    let stl_len += (&buftype == 'help') ? 6 : 0        " Status flag 'h'. Can be '[Help]'
    let stl_len += (&modified || !&modifiable) ? 3 : 0 " Status flag 'm'. Can be '[+]' or '[-]'
    let stl_len += (&readonly) ? 4 : 0                 " Status flag 'r'. Can be '[RO]'
    let stl_len += (&previewwindow) ? 9 : 0            " Status flag 'w'. Can be '[Preview]'

    let stl_len += bufnr + 3         " Buffer number + 2 parentheses + 1 w/space
    let stl_len += strlen(fname) + 1 " File name + 1 whitespace
    let stl_len += strlen(ftype) + 3 " File type + 2 sq/brackets + 1 w/space
    let stl_len += strlen(&fileformat) + 3 " File format + 2 sq/brackets + 1 w/space
    let stl_len += strlen(scm_stat) + 1 " SCM status + 1 whitespace

   " line_curr = line('.'), lines_num = line('$'), col_curr  = col('.'), cols_num  = col('$')-1
    " Current line number + lines number + 1 slash + 1 colon + 3 reserved space for current
    " cursor position in line + 1 whitespace
    let stl_len += strlen(line('.') . line('$')) + 6

    let stl_len += 6 " Length of max value - '(100%)'

    let l:is_format_slim = winwidth(0) <= stl_len

    let stl_len += strlen(v:lang) + 1 " Language + 1 slash
    let stl_len += 20 " Defined date/time format - length always the same: 19 + 1 whitespace
    let stl_len += 5  " Char value. It always '0x0' or 4-char length like '0x3A'

    let l:is_format_full = winwidth(0) >= stl_len

    let l:ret = ''

    let ret .= '%h%m%r%w'     " status flags
    let ret .= '(%n)'         " buffer number
    let ret .= exists('g:WATCHDOG_COLORS_LOADED') && a:is_in_focus ? '%1*' : ''
    let ret .= ' '.fname      " just filename, without path
    let ret .= exists('g:WATCHDOG_COLORS_LOADED') ? '%3*' : ''
    let ret .= ' ['.ftype.']' " file type

    " File format / current language (in full format only file format)
    let ret .= is_format_full ? ' [%{&ff}/%{v:lang}]' : (is_format_slim ? '' : ' [%{&ff}]')

    " SCM info: current branch and so (not in slim format)
    let ret .= is_format_slim ? '' : ' '.scm_stat

    " Current file modification date/time (only in full format)
    let ret .= is_format_full ? ' '.datetime : ''

    let ret .= '%=' " right align remainder

    " Character value (only in format mode)
    let ret .= is_format_full ? ' 0x%-8B' : ''

    " Line, character position (in slim format only lines)
    let ret .= is_format_slim ? ' %l/%L' : ' %-12(%l/%L:%c%V%)'
    " Cursor position in percent (not in slim format)
    let ret .= is_format_slim ? '' : ' (%p%%)'

    let &l:statusline = l:ret
endfunction
