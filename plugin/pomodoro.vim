if exists('g:pomodoro_loaded')
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! PomodoroStart lua require'pomodoro'.start()
command! PomodoroStatus lua require'pomodoro'.status()
command! PomodoroStop lua require'pomodoro'.stop()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:pomodoro_loaded = 1
