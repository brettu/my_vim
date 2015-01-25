" plugin/pomodoro.vim
" Author:   Maximilian Nickel <max@inmachina.com>
" License:  MIT License 
"
" Vim plugin for the Pomodoro time management technique. 
"
" Commands:
"	:PomodoroStart [name]	-	Start a new pomodoro. [name] is optional.
"
" Configuration: 
"	g:pomodoro_time_work	-	Duration of a pomodoro 
"	g:pomodoro_time_slack	-	Duration of a break 
"	g:pomodoro_log_file		-	Path to log file

if &cp || exists("g:pomodoro_loaded") && g:pomodoro_loaded
  finish
endif

let g:pomodoro_loaded = 1
let g:pomodoro_started = 0
let g:pomodoro_started_at = -1 

let g:pomodoro_time_work = 25
let g:pomodoro_time_slack = 5

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* PomodoroStart call s:PomodoroStart(<q-args>)
nmap <F7> <ESC>:PomodoroStart<CR>

function! PomodoroStatus() 
	if g:pomodoro_started == 0
		return "Pomodoro inactive"
	elseif g:pomodoro_started == 1
		return "Pomodoro started (remaining: " . pomodorocommands#remaining_time() . " minutes)"
	elseif g:pomodoro_started == 2
		return "Pomodoro break started"
	endif
endfunction

function! s:PomodoroStart(name)
	if g:pomodoro_started != 1
		if a:name == ''
			let name = '(unnamed)'
		else 
			let name = a:name
		endif
		call asynccommand#run("sleep " . g:pomodoro_time_work * 60, pomodorohandlers#pause(name)) 
		let g:pomodoro_started_at = localtime()
		let g:pomodoro_started = 1 
	endif
endfunction



if exists("g:loaded_autoload_pomodorocommands") || &cp || !has('clientserver')
    " requires nocompatible and clientserver
    " also, don't double load
    finish
endif
let g:loaded_autoload_pomodorocommands = 1

function! pomodorocommands#notify()
	if exists("g:pomodoro_notification_cmd") 
		call asynccommand#run(g:pomodoro_notification_cmd)
	endif
endfunction

function! pomodorocommands#remaining_time() 
	return (g:pomodoro_time_work * 60 - abs(localtime() - g:pomodoro_started_at)) / 60
endfunction


" autoload/pomodorohandlers.vim
" Author:   Maximilian Nickel <max@inmachina.com>
" License:  MIT License

if exists("g:loaded_autoload_pomodorohandlers") || &cp || !has('clientserver')
    " requires nocompatible and clientserver
    " also, don't double load
    finish
endif
let g:loaded_autoload_pomodorohandlers = 1

function! pomodorohandlers#pause(name)
    " Load the result in a split
    let env = {'name' : a:name}
    function env.get(temp_file_name) dict
		call pomodorocommands#notify()
		let choice = confirm("Great, pomodoro " . self.name . " is finished!\nNow, take a break for " . g:pomodoro_time_slack . " minutes", "&OK")
		let g:pomodoro_started = 0 
		if exists("g:pomodoro_log_file")
			exe "!echo 'Pomodoro " . self.name . " ended at " . strftime("%c") . ", duration: " . g:pomodoro_time_work . " minutes' >> " . g:pomodoro_log_file
		endif
		call asynccommand#run("sleep " . g:pomodoro_time_slack * 60, pomodorohandlers#restart())
    endfunction 
    return asynccommand#tab_restore(env)
endfunction

function! pomodorohandlers#restart()
    " Load the result in a split
    let env = {}
    function env.get(temp_file_name) dict
		call pomodorocommands#notify()
		let choice = confirm(g:pomodoro_time_slack . " minutes break is over... Feeling rested?\nWant to start another pomodoro?", "&Yes\n&No")
		if choice == 1
			call StartPomodoro()
		endif
    endfunction
    return asynccommand#tab_restore(env)
endfunction
