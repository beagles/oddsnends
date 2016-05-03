
function! DiaryEntry()
python << EOF
import vim
import datetime
vim.current.buffer[0:0] = [""]
vim.current.buffer[0:0] = [""]
vim.current.buffer[0:0] = [""]
vim.current.buffer[0:0] = [datetime.date.today().strftime("%Y-%m-%d %A")] # prepend date to current buffer
vim.current.buffer[0:0] = ["==========================================================================="]
EOF
call cursor(4,1)
endfunction

function! LogDaySection()
  let foo = append(line('$'), "===========================================================================")
  let foo = append(line('$'), strftime("%Y-%m-%d %A"))
  let foo = append(line('$'), "")
  let foo = setpos('.', [bufnr('%'), line('$'), 1, 0])
endfunction

function! PrintTime()
python << EOF
import vim
import datetime
vim.current.line = str(datetime.datetime.today().strftime("%H:%M")) + ' ' + vim.current.line
EOF
endfunction

function! FormatJSON()
python << EOF
import vim
import json
first_brace = vim.current.line.find('{')
last_brace = vim.current.line.rfind('}')
if first_brace >= 0 and last_brace >= 0:
    data = vim.current.line
    current_row = vim.current.window.cursor[0]
    data = data[first_brace:last_brace+1]
    foo = json.loads(data)
    rest_of_line = vim.current.line[last_brace+1:]
    vim.current.line = vim.current.line[:first_brace]
    lines_to_add = json.dumps(json.loads(data), sort_keys=True, indent=2).split('\n')
    lines_to_add = [x.rstrip() for x in lines_to_add]
    lines_to_add.append(rest_of_line)
    vim.current.buffer.append(lines_to_add, current_row)
    vim.current.window.cursor = (current_row + len(lines_to_add), 0)
EOF
endfunction

function! Log()
    let l:cl = line(".")
    call append(cl, "")
    let l:cl = l:cl + 1
    call cursor(cl, 1)
    call PrintTime()
endfunction

function! XLine()
python << EOF
import vim
vim.current.line = 'X ' + vim.current.line
EOF
endfunction


function! PrintDate()
python << EOF
import vim
import datetime
vim.current.line = str(datetime.date.today()) + ' ' + vim.current.line # prepend date to current line
EOF
endfunction

fun! FlipHeader()
    "" Switch between a C/C++ header file and the source.

    let mybuf = bufname("%")
    let ext = fnamemodify(mybuf, ":e")
    let rootfilename = fnamemodify(mybuf, ":p:r")
    let newext = ""
    if ext == "h"
	if filereadable(rootfilename.".cpp")
	    let newext = ".cpp"
	elseif filereadable(rootfilename, ".cxx")
	    let newext = ".cxx"
	elseif filereadable(rootfilename, ".c")
	    let newext = ".c"
	else

	    "" The end result here will be to create a new C++ source file.

	    let newext = ".cpp"
	endif
    elseif ext == "c" || ext == "cpp"
	let newext = ".h"
    endif
    exe "edit " . rootfilename . newext
endfun

"" Sets thing up for BufSwitch()
if has("autocmd")
    autocmd BufEnter * let g:bufSwitchCurrent = bufnr("%")
    autocmd BufLeave * let g:bufSwitchPrev = bufnr("%")
endif

fun! BufSwitch()
    "" The whole point here is to set up a quick toggling between two
    "" adjacent buffers while editing multiple files.
    if g:bufSwitchPrev == ""
	exe "bn"
    else
	if g:bufSwitchCurrent > g:bufSwitchPrev || g:bufSwitchPrev > bufnr("$")
	    while ! bufloaded(g:bufSwitchPrev)
		let g:bufSwitchPrev = g:bufSwitchPrev - 1
		if g:bufSwitchPrev < 0
		    let g:bufSwitchPrev = bufnr("$")
		    break
		endif
	    endw
	else
	    while ! bufloaded(g:bufSwitchPrev) && g:bufSwitchPrev != g:bufSwitchCurrent
		let g:bufSwitchPrev = g:bufSwitchPrev + 1
		if g:bufSwitchPrev > bufnr("$") 
		    let g:bufSwitchPrev = 0
		endif
	    endw
	endif
	exe "b " . g:bufSwitchPrev
    endif
endfun

fun! InsModLog()
    call Log()
    call col("$")
endfun

command! Dia call DiaryEntry()
command! Dat call PrintDate()
command! Now call PrintTime()
command! Jdr call LogDaySection()
command! NextBuffer call BufSwitch()
map <F6> :call FlipHeader()<CR>
map <M-n> :call BufSwitch()<CR>

"" Straight mapping to F7 causes all kinds of shit since it so close to F6.
map <M-F7> :call PrintTime()<CR>

map <M-l> :call Log()<CR>A
"" imap <M-l> :call Log()<CR>call col("$")<CR>

map fc gq/^\s*\/\/$<CR>
