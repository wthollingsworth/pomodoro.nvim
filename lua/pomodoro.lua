vim.g.pomodoro_time_work = 25
vim.g.pomodoro_time_break_short = 5
vim.g.pomodoro_time_break_long = 20
vim.g.pomodoro_timers_to_long_break = 4

local pomodoro_state = 'stopped'
local pomodoro_work_started_at = 0
local pomodoro_break_started_at = 0
local pomodoro_timers_completed = 0
local pomodoro_uv_timer = nil

local function pomodoro_time_break()
    if pomodoro_timers_completed == 0 then
        return vim.g.pomodoro_time_break_long
    else
        return vim.g.pomodoro_time_break_short
    end
end

local function pomodoro_time_remaining(duration, start)
    local seconds = duration * 60 - os.difftime(os.time(), start)
    if math.floor(seconds / 60) >= 60 then
        return os.date('!%0H:%0M:%0S', seconds)
    else
        return os.date('!%0M:%0S', seconds)
    end
end

local display_pomodoro_completed_menu
local function start_pomodoro()
    if pomodoro_state ~= 'started' then
        local work_milliseconds = vim.g.pomodoro_time_work * 60 * 1000
        pomodoro_uv_timer:start(work_milliseconds, 0, vim.schedule_wrap(display_pomodoro_completed_menu))
        pomodoro_work_started_at = os.time()
        pomodoro_state = 'started'
    end
end

local display_break_completed_menu
local function start_break()
    if pomodoro_state == 'started' then
        pomodoro_timers_completed = (pomodoro_timers_completed + 1) % vim.g.pomodoro_timers_to_long_break
        local break_milliseconds = pomodoro_time_break() * 60 * 1000
        pomodoro_uv_timer:start(break_milliseconds, 0, vim.schedule_wrap(display_break_completed_menu))
        pomodoro_break_started_at = os.time()
        pomodoro_state = 'break'
    end
end

local Pomodoro = {}

function Pomodoro.start()
    if pomodoro_state == 'stopped' then
        pomodoro_uv_timer = vim.loop.new_timer()
        start_pomodoro()
    end
end

function Pomodoro.statusline()
    if pomodoro_state == 'stopped' then
        return 'ﮫ (inactive)'
    elseif pomodoro_state == 'started' then
        return '羽' .. pomodoro_time_remaining(vim.g.pomodoro_time_work, pomodoro_work_started_at)
    else
        local break_minutes = pomodoro_time_break()
        return 'ﲊ ' .. pomodoro_time_remaining(break_minutes, pomodoro_break_started_at)
    end
end

function Pomodoro.status()
    print(Pomodoro.statusline())
end

function Pomodoro.stop()
    if pomodoro_state ~= 'stopped' then
        pomodoro_uv_timer:stop()
        pomodoro_uv_timer:close()
        pomodoro_state = 'stopped'
    end
end

function Pomodoro.setup(tbl)
    if tbl.time_work then
        vim.g.pomodoro_time_work = tbl.time_work
    end

    if tbl.time_break_short then
        vim.g.pomodoro_time_break_short = tbl.time_break_short
    end

    if tbl.time_break_long then
        vim.g.pomodoro_time_break_long = tbl.time_break_long
    end

    if tbl.timers_to_long_break then
        vim.g.pomodoro_timers_to_long_break = tbl.timers_to_long_break
    end
end

local Menu = require('nui.menu')
local event = require('nui.utils.autocmd').event

display_pomodoro_completed_menu = function()
    local popup_options = {
        border = {
            style = 'rounded',
            text = {
                top_align = 'left',
                top = '[Pomodoro Completed]'
            },
            padding = { 1, 3 },
        },
        position = '50%',
        size = {
            width = '25%',
        },
        opacity = 1,
    }

    local menu_options = {
        keymap = {
            focus_next = { 'j', '<Down>', '<Tab>' },
            focus_prev = { 'k', '<Up>', '<S-Tab>' },
            close = { '<Esc>', '<C-c>' },
            submit = { '<CR>', '<Space>' },
        },
        lines = { Menu.item('Take break'), Menu.item('Quit') },
        on_close = Pomodoro.stop,
        on_submit = function(item)
            if item.text == 'Quit' then
                Pomodoro.stop()
            else
                start_break()
            end
        end
    }
    local menu = Menu(popup_options, menu_options)
    menu:mount()
    menu:on(event.BufLeave, function()
        Pomodoro.stop()
        menu:unmount()
    end, { once = true })
    menu:map('n', 'b', function()
        start_break()
        menu:unmount()
    end, { noremap = true })
    menu:map('n', 'q', function()
        Pomodoro.stop()
        menu:unmount()
    end, { noremap = true })
end

display_break_completed_menu = function()
    local popup_options = {
        border = {
            style = 'rounded',
            text = {
                top_align = 'left',
                top = '[Break Completed]'
            },
            padding = { 1, 3 },
        },
        position = '50%',
        size = {
            width = '25%',
        },
        opacity = 1,
    }

    local menu_options = {
        keymap = {
            focus_next = { 'j', '<Down>', '<Tab>' },
            focus_prev = { 'k', '<Up>', '<S-Tab>' },
            close = { '<Esc>', '<C-c>' },
            submit = { '<CR>', '<Space>' },
        },
        lines = { Menu.item('Start pomodoro'), Menu.item('Quit') },
        on_close = Pomodoro.stop,
        on_submit = function(item)
            if item.text == 'Quit' then
                Pomodoro.stop()
            else
                start_pomodoro()
            end
        end
    }

    local menu = Menu(popup_options, menu_options)
    menu:mount()
    menu:on(event.BufLeave, function()
        Pomodoro.stop()
        menu:unmount()
    end, { once = true })
    menu:map('n', 'p', function()
        start_pomodoro()
        menu:unmount()
    end, { noremap = true })
    menu:map('n', 'q', function()
        Pomodoro.stop()
        menu:unmount()
    end, { noremap = true })
end

return Pomodoro
