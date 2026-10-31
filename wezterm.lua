-- Everyday WezTerm config.
-- Copy this file to ~/.config/wezterm/wezterm.lua (or %USERPROFILE%\.wezterm.lua on Windows).
-- WezTerm reloads it automatically when you save.
--
-- Leader is Ctrl-a, in the same spirit as tmux. Press Ctrl-a twice to send a real Ctrl-a
-- through to the shell (beginning-of-line in readline and Emacs).
-- Press Ctrl-a then ? to open the key list in a new tab.

local wezterm = require 'wezterm'
local act = wezterm.action

local config = {}
if wezterm.config_builder then
config = wezterm.config_builder()
end

-- Catppuccin Mocha ships with WezTerm. Other built-in favorites:
-- 'Catppuccin Macchiato', 'Tokyo Night', 'Dracula', 'Gruvbox Dark', 'Nord', 'rose-pine'
config.color_scheme = 'Catppuccin Mocha'

-- JetBrains Mono is bundled, so this works even when the font is not installed system-wide.
-- Nerd Font symbols and Noto Color Emoji are also bundled and used as fallbacks.
config.font = wezterm.font_with_fallback {
{ family = 'JetBrains Mono', weight = 'Regular' },
'Symbols Nerd Font Mono',
'Noto Color Emoji',
}
config.font_size = 13.0
config.line_height = 1.05
config.harfbuzz_features = { 'calt=1', 'liga=1', 'clig=1' }

config.default_cursor_style = 'SteadyBar'
config.cursor_thickness = 1.5
config.force_reverse_video_cursor = true

config.window_decorations = 'RESIZE'
config.window_padding = { left = 12, right = 8, top = 10, bottom = 6 }
config.initial_cols = 120
config.initial_rows = 32
config.adjust_window_size_when_changing_font_size = false

-- The clock and workspace live in the tab bar, so keep the bar visible with one tab.
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.show_tab_index_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 28

config.colors = {
-- One bright divider color. WezTerm cannot paint only the active pane's edge.
split = '#89b4fa',
tab_bar = {
background = '#11111b',
active_tab = {
bg_color = '#1e1e2e',
fg_color = '#cdd6f4',
intensity = 'Bold',
},
inactive_tab = {
bg_color = '#181825',
fg_color = '#6c7086',
},
inactive_tab_hover = {
bg_color = '#313244',
fg_color = '#cdd6f4',
},
new_tab = {
bg_color = '#11111b',
fg_color = '#6c7086',
},
new_tab_hover = {
bg_color = '#313244',
fg_color = '#cdd6f4',
},
},
}

-- Dim and wash out every pane that is not focused. The active pane keeps
-- the normal Catppuccin colors, so it stays the bright one.
config.inactive_pane_hsb = {
saturation = 0.4,
brightness = 0.2,
}

config.scrollback_lines = 10000
config.scroll_to_bottom_on_input = true
config.hide_mouse_cursor_when_typing = true
config.audible_bell = 'Disabled'
config.warn_about_missing_glyphs = false
config.automatically_reload_config = true
config.window_close_confirmation = 'AlwaysPrompt'
config.max_fps = 120

-- Leave the login shell alone (/bin/bash / the Windows user default).
-- Uncomment to force one:
-- config.default_prog = { '/bin/zsh', '-l' }
-- config.default_prog = { 'pwsh.exe', '-NoLogo' }

config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1500 }

local tldr = [[
Ctrl-a is the prefix. Press it, then the key. Press Ctrl-a twice to send a real Ctrl-a to the shell.

c new tab
, rename tab
n / p next / previous tab
1-8 jump to that tab
9 jump to the last tab
\ split right, new shell
| move another tab to the right
- split down, new shell
_ move another tab below
h j k l move between panes
z zoom the current pane
r resize panes (h j k l, then Esc)
x close pane
X close tab
[ copy mode
/ search scrollback
Space grab a path or URL
? show this list

Copy mode
h j k l move
w / b next / previous word
e end of the word
0 start of the line
g / G top / bottom of the scrollback
v, then y select and copy
V select whole lines
q or Esc leave

Copy and paste stay on Ctrl-Shift-c and Ctrl-Shift-v (Cmd-c and Cmd-v on macOS).
Option-Left and Option-Right move one word. On Linux that is Alt-Left and Alt-Right.
]]

local function shell_quote(value)
local quote = string.char(39)
local escaped = quote .. string.char(92) .. quote .. quote
return quote .. tostring(value):gsub(quote, escaped) .. quote
end

local function show_tldr()
-- Write the list to a file when the key is pressed. The path is inlined into
-- the command because extra arguments after sh -c are not passed through.
return wezterm.action_callback(function(window, pane)
local sep = package.config:sub(1, 1)
local home = wezterm.home_dir
if not home or home == '' then
home = os.getenv 'HOME' or os.getenv 'USERPROFILE' or '.'
end
local dir = home .. sep .. '.cache'
local path = dir .. sep .. 'wezterm-keys.txt'
os.execute('mkdir -p ' .. shell_quote(dir))

local file = io.open(path, 'w')
if file then
file:write(tldr)
file:close()
end

-- One line, and no pager. A multiline command or less can exit immediately,
-- and WezTerm then closes the tab before the list can be read.
local args
if wezterm.target_triple:find 'windows' then
args = {
'powershell.exe',
'-NoProfile',
'-Command',
"Get-Content -LiteralPath '" .. path:gsub("'", "''") .. "'; Read-Host 'Press Enter to close'",
}
else
local quoted = shell_quote(path)
args = {
'/bin/sh',
'-c',
'cat -- ' .. quoted .. [[ || printf "Could not open the key list\n"; printf "\nPress Enter to close\n"; read _ </dev/tty || read _]],
}
end

window:perform_action(act.SpawnCommandInNewTab { args = args }, pane)
end)
end

local function join_existing_pane(direction)
return wezterm.action_callback(function(window, pane)
local choices = {}
local current_id = tostring(pane:pane_id())
local tab_index = 0
for _, tab in ipairs(window:mux_window():tabs()) do
tab_index = tab_index + 1
local tab_title = tab:get_title() or ''
for _, other in ipairs(tab:panes()) do
local other_id = tostring(other:pane_id())
if other_id ~= current_id then
local pane_title = other:get_title() or ''
local label = string.format('%d %s', tab_index, tab_title)
if pane_title ~= '' and pane_title ~= tab_title then
label = label .. ' ' .. pane_title
end
table.insert(choices, { id = other_id, label = label })
end
end
end

if #choices == 0 then
window:toast_notification(
'WezTerm',
'No other tab to move. Ctrl-a then backslash, or Ctrl-a -, starts a new shell in this tab.',
nil,
4000
)
return
end

window:perform_action(
act.InputSelector {
title = 'Move a tab into this split',
description = 'Enter accepts, Esc cancels. An emptied tab is closed.',
choices = choices,
fuzzy = true,
action = wezterm.action_callback(function(_, current, id)
if not id then
return
end
local exe = 'wezterm'
if wezterm.executable_dir and wezterm.executable_dir ~= '' then
local sep = package.config:sub(1, 1)
exe = wezterm.executable_dir .. sep .. 'wezterm'
if wezterm.target_triple:find 'windows' then
exe = exe .. '.exe'
end
end
wezterm.run_child_process {
exe,
'cli',
'split-pane',
'--pane-id',
tostring(current:pane_id()),
'--move-pane-id',
id,
direction,
}
end),
},
pane
)
end)
end

-- ESC b / ESC f are the readline and zsh word motions, same as Option-arrow on macOS.
local word_back = act.SendString(string.char(27) .. 'b')
local word_forward = act.SendString(string.char(27) .. 'f')

config.keys = {
{ key = 'a', mods = 'LEADER|CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },

{ key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
{ key = 'n', mods = 'LEADER|SHIFT', action = act.SpawnWindow },
{ key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
{ key = 'x', mods = 'LEADER|SHIFT', action = act.CloseCurrentTab { confirm = true } },

{ key = string.char(92), mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
{ key = '|', mods = 'LEADER|SHIFT', action = join_existing_pane '--right' },
{ key = '-', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
{ key = '_', mods = 'LEADER|SHIFT', action = join_existing_pane '--bottom' },

{ key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
{ key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
{ key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
{ key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
{ key = 'LeftArrow', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
{ key = 'DownArrow', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
{ key = 'UpArrow', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
{ key = 'RightArrow', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
{ key = 'LeftArrow', mods = 'ALT', action = word_back },
{ key = 'RightArrow', mods = 'ALT', action = word_forward },

{ key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
{ key = 's', mods = 'LEADER', action = act.PaneSelect { mode = 'Activate' } },
{
key = 'r',
mods = 'LEADER',
action = act.ActivateKeyTable {
name = 'resize_pane',
one_shot = false,
},
},

{ key = '[', mods = 'LEADER', action = act.ActivateCopyMode },
{ key = '/', mods = 'LEADER', action = act.Search { CaseInSensitiveString = '' } },
{ key = ' ', mods = 'LEADER', action = act.QuickSelect },
{ key = 'p', mods = 'LEADER|SHIFT', action = act.ActivateCommandPalette },

{ key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
{ key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
{ key = 'Tab', mods = 'LEADER', action = act.ActivateTabRelative(1) },
{ key = 'Tab', mods = 'LEADER|SHIFT', action = act.ActivateTabRelative(-1) },
{ key = '{', mods = 'LEADER|SHIFT', action = act.MoveTabRelative(-1) },
{ key = '}', mods = 'LEADER|SHIFT', action = act.MoveTabRelative(1) },

{
key = ',',
mods = 'LEADER',
action = act.PromptInputLine {
description = 'Rename tab',
action = wezterm.action_callback(function(window, _pane, line)
if line then
window:active_tab():set_title(line)
end
end),
},
},

{ key = 'r', mods = 'LEADER|SHIFT', action = act.ReloadConfiguration },
{ key = '?', mods = 'LEADER|SHIFT', action = show_tldr() },
}

for i = 1, 8 do
table.insert(config.keys, {
key = tostring(i),
mods = 'LEADER',
action = act.ActivateTab(i - 1),
})
end
table.insert(config.keys, {
key = '9',
mods = 'LEADER',
action = act.ActivateTab(-1),
})

config.key_tables = {
resize_pane = {
{ key = 'h', action = act.AdjustPaneSize { 'Left', 3 } },
{ key = 'j', action = act.AdjustPaneSize { 'Down', 1 } },
{ key = 'k', action = act.AdjustPaneSize { 'Up', 1 } },
{ key = 'l', action = act.AdjustPaneSize { 'Right', 3 } },
{ key = 'LeftArrow', action = act.AdjustPaneSize { 'Left', 3 } },
{ key = 'DownArrow', action = act.AdjustPaneSize { 'Down', 1 } },
{ key = 'UpArrow', action = act.AdjustPaneSize { 'Up', 1 } },
{ key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 3 } },
{ key = 'Escape', action = 'PopKeyTable' },
{ key = 'Return', action = 'PopKeyTable' },
{ key = 'q', action = 'PopKeyTable' },
},
}

local function display_cwd(pane)
local cwd_uri = pane:get_current_working_dir()
if not cwd_uri then
return ''
end

local path
if type(cwd_uri) == 'userdata' then
path = cwd_uri.file_path
else
path = tostring(cwd_uri):gsub('^file://[^/]*', '')
path = path:gsub('%%(%x%x)', function(hex)
return string.char(tonumber(hex, 16))
end)
end
if not path or path == '' then
return ''
end

local home = os.getenv 'HOME' or os.getenv 'USERPROFILE'
if home and path:sub(1, #home) == home then
path = '~' .. path:sub(#home + 1)
end

local parts = {}
for part in path:gmatch('[^/' .. string.char(92) .. ']+') do
table.insert(parts, part)
end
if #parts > 2 then
return parts[#parts - 1] .. '/' .. parts[#parts]
end
return table.concat(parts, '/')
end

local function agent_state(tab)
local panes = tab.panes
if not panes and tab.active_pane then
panes = { tab.active_pane }
end
local state = nil
for _, info in ipairs(panes or {}) do
local vars = info.user_vars or {}
if vars.agent == 'waiting' then
return 'waiting'
end
if vars.agent == 'working' then
state = 'working'
elseif vars.agent == 'done' and state ~= 'working' then
state = 'done'
end
end
return state
end

local function tab_label(tab)
local title = tab.tab_title
if title and title ~= '' then
return title
end
local active = tab.active_pane
if active and active.title and active.title ~= '' then
return active.title
end
return ''
end

-- Emoji prefix only: hourglass = waiting for input, check = finished, gear = working.
-- The agent sets the user var with hooks/agent-status.sh.
wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, _hover, max_width)
local state = agent_state(tab)
local colors
local prefix = ''
if state == 'waiting' then
prefix = ' ⏳'
elseif state == 'done' then
prefix = ' ✅'
elseif state == 'working' then
prefix = ' ⚙️'
end
if tab.is_active then
colors = { bg = '#89b4fa', fg = '#11111b' }
else
colors = { bg = '#181825', fg = '#6c7086' }
end

local text = ' ' .. tostring(tab.tab_index + 1) .. ' ' .. tab_label(tab) .. prefix .. ' '
if max_width and max_width > 0 and #text > max_width then
text = text:sub(1, max_width)
end

return {
{ Background = { Color = '#11111b' } },
{ Foreground = { Color = '#45475a' } },
{ Text = '▏' },
{ Background = { Color = colors.bg } },
{ Foreground = { Color = colors.fg } },
{ Text = text },
}
end)

wezterm.on('update-status', function(window, pane)
local palette = {
base = '#1e1e2e',
surface = '#313244',
text = '#cdd6f4',
subtext = '#a6adc8',
mauve = '#cba6f7',
blue = '#89b4fa',
crust = '#11111b',
}

local label = window:active_workspace()
local label_bg = palette.surface
local label_fg = palette.text
if window:leader_is_active() then
label = 'LEADER'
label_bg = palette.mauve
label_fg = palette.crust
end

window:set_left_status(wezterm.format {
{ Background = { Color = label_bg } },
{ Foreground = { Color = label_fg } },
{ Text = ' ' .. label .. ' ' },
})

local pieces = {}
local cwd = display_cwd(pane)
if cwd ~= '' then
table.insert(pieces, cwd)
end

local batteries = {}
for _, battery in ipairs(wezterm.battery_info()) do
table.insert(batteries, string.format('%d%%', math.floor(battery.state_of_charge * 100 + 0.5)))
end
if #batteries > 0 then
table.insert(pieces, table.concat(batteries, ' '))
end

local host = wezterm.hostname():gsub('%..*', '')
table.insert(pieces, host)

window:set_right_status(wezterm.format {
{ Background = { Color = palette.base } },
{ Foreground = { Color = palette.subtext } },
{ Text = ' ' .. table.concat(pieces, ' · ') .. ' ' },
{ Background = { Color = palette.surface } },
{ Foreground = { Color = palette.blue } },
{ Text = ' ' .. wezterm.strftime '%a %b %-d %H:%M' .. ' ' },
})
end)

return config

