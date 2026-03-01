-- WezTerm Config - kaldown
-- Leader: CTRL+Space | Splits: |/- | Nav: CTRL+SHIFT+hjkl | Resize: Leader+r

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ════════════════════════════════════════════════════════════════════════════
-- STABILITY: Use OpenGL backend to avoid WebGpu/Metal crashes on macOS
-- See: https://github.com/wezterm/wezterm/issues/7118
-- ════════════════════════════════════════════════════════════════════════════

config.front_end = 'OpenGL'

-- ════════════════════════════════════════════════════════════════════════════
-- APPEARANCE
-- ════════════════════════════════════════════════════════════════════════════

config.color_scheme = 'Catppuccin Macchiato'
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = 14.0
config.line_height = 1.2

-- Disable shadows (linked to macOS crashes), keep resize handles
config.window_decorations = 'MACOS_FORCE_DISABLE_SHADOW | RESIZE'
config.window_padding = { left = 5, right = 5, top = 5, bottom = 5 }

-- Transparency without blur (blur stresses GPU on sleep/wake cycles)
config.window_background_opacity = 0.95

-- ════════════════════════════════════════════════════════════════════════════
-- TAB BAR
-- ════════════════════════════════════════════════════════════════════════════

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32

config.colors = {
  tab_bar = {
    background = '#1e2030',
    active_tab = {
      bg_color = '#c6a0f6',
      fg_color = '#1e2030',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#363a4f',
      fg_color = '#cad3f5',
    },
    inactive_tab_hover = {
      bg_color = '#494d64',
      fg_color = '#cad3f5',
    },
    new_tab = {
      bg_color = '#1e2030',
      fg_color = '#6e738d',
    },
    new_tab_hover = {
      bg_color = '#494d64',
      fg_color = '#cad3f5',
    },
  },
}

config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.7,
}

-- ════════════════════════════════════════════════════════════════════════════
-- PERFORMANCE (tuned for stability with many Claude Code sessions)
-- ════════════════════════════════════════════════════════════════════════════

config.max_fps = 60
config.animation_fps = 10
config.scrollback_lines = 5000
config.enable_scroll_bar = false

-- ════════════════════════════════════════════════════════════════════════════
-- LEADER KEY
-- ════════════════════════════════════════════════════════════════════════════

config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }

-- ════════════════════════════════════════════════════════════════════════════
-- KEYBINDINGS
-- ════════════════════════════════════════════════════════════════════════════

config.keys = {
  -- Send CTRL+Space to terminal when pressed twice
  { key = 'Space', mods = 'LEADER|CTRL',  action = act.SendKey { key = 'Space', mods = 'CTRL' } },

  -- ══════════════════════════════════════════════════════════════════════════
  -- SPLITS (tmux-style)
  -- ══════════════════════════════════════════════════════════════════════════
  { key = '|',     mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-',     mods = 'LEADER',       action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- ══════════════════════════════════════════════════════════════════════════
  -- PANE NAVIGATION (vim-style)
  -- ══════════════════════════════════════════════════════════════════════════
  { key = 'h',     mods = 'CTRL|SHIFT',   action = act.ActivatePaneDirection 'Left' },
  { key = 'j',     mods = 'CTRL|SHIFT',   action = act.ActivatePaneDirection 'Down' },
  { key = 'k',     mods = 'CTRL|SHIFT',   action = act.ActivatePaneDirection 'Up' },
  { key = 'l',     mods = 'CTRL|SHIFT',   action = act.ActivatePaneDirection 'Right' },
  { key = 'h',     mods = 'SUPER',        action = act.ActivatePaneDirection 'Left' },
  { key = 'j',     mods = 'SUPER',        action = act.ActivatePaneDirection 'Down' },
  { key = 'k',     mods = 'SUPER',        action = act.ActivatePaneDirection 'Up' },
  { key = 'l',     mods = 'SUPER',        action = act.ActivatePaneDirection 'Right' },

  -- ══════════════════════════════════════════════════════════════════════════
  -- PANE MANAGEMENT
  -- ══════════════════════════════════════════════════════════════════════════
  { key = 'z',     mods = 'LEADER',       action = act.TogglePaneZoomState },
  { key = 'x',     mods = 'LEADER',       action = act.CloseCurrentPane { confirm = true } },
  { key = 'w',     mods = 'LEADER',       action = act.PaneSelect },
  { key = 'W',     mods = 'LEADER|SHIFT', action = act.PaneSelect { mode = 'SwapWithActive' } },
  { key = 'o',     mods = 'LEADER',       action = act.RotatePanes 'Clockwise' },

  -- ══════════════════════════════════════════════════════════════════════════
  -- RESIZE MODE
  -- ══════════════════════════════════════════════════════════════════════════
  {
    key = 'r',
    mods = 'LEADER',
    action = act.ActivateKeyTable { name = 'resize_pane', one_shot = false },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  -- TABS
  -- ══════════════════════════════════════════════════════════════════════════
  { key = 'c',          mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'n',          mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'p',          mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  { key = 'LeftArrow',  mods = 'SUPER',  action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'SUPER',  action = act.ActivateTabRelative(1) },
  { key = '&', mods = 'LEADER|SHIFT', action = act.CloseCurrentTab { confirm = true } },
  {
    key = ',',
    mods = 'LEADER',
    action = act.PromptInputLine {
      description = 'Enter new tab name:',
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  -- WORKSPACES
  -- ══════════════════════════════════════════════════════════════════════════
  { key = 's',     mods = 'LEADER',     action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  {
    key = 'S',
    mods = 'LEADER|SHIFT',
    action = act.PromptInputLine {
      description = 'Enter workspace name:',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:perform_action(act.SwitchToWorkspace { name = line }, pane)
        end
      end),
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  -- UTILITIES
  -- ══════════════════════════════════════════════════════════════════════════
  { key = '[',     mods = 'LEADER',     action = act.ActivateCopyMode },
  { key = 'f',     mods = 'LEADER',     action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 'P',     mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
  { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },
}

-- Quick tab switching (Leader + 1-9)
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'LEADER',
    action = act.ActivateTab(i - 1),
  })
end

-- ════════════════════════════════════════════════════════════════════════════
-- KEY TABLES (Modal Modes)
-- ════════════════════════════════════════════════════════════════════════════

config.key_tables = {
  resize_pane = {
    { key = 'h',          action = act.AdjustPaneSize { 'Left', 2 } },
    { key = 'j',          action = act.AdjustPaneSize { 'Down', 2 } },
    { key = 'k',          action = act.AdjustPaneSize { 'Up', 2 } },
    { key = 'l',          action = act.AdjustPaneSize { 'Right', 2 } },
    { key = 'LeftArrow',  action = act.AdjustPaneSize { 'Left', 2 } },
    { key = 'DownArrow',  action = act.AdjustPaneSize { 'Down', 2 } },
    { key = 'UpArrow',    action = act.AdjustPaneSize { 'Up', 2 } },
    { key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 2 } },
    { key = 'Escape',     action = act.PopKeyTable },
    { key = 'Enter',      action = act.PopKeyTable },
    { key = 'q',          action = act.PopKeyTable },
  },
}

-- ════════════════════════════════════════════════════════════════════════════
-- STATUS BAR
-- ════════════════════════════════════════════════════════════════════════════

wezterm.on('update-right-status', function(window, _)
  local cells = {}

  -- Leader indicator
  if window:leader_is_active() then
    table.insert(cells, { Foreground = { Color = '#ed8796' } }) -- Red
    table.insert(cells, { Text = ' LEADER ' })
  end

  -- Key table indicator (e.g., RESIZE)
  local key_table = window:active_key_table()
  if key_table then
    table.insert(cells, { Foreground = { Color = '#f5a97f' } }) -- Peach
    table.insert(cells, { Text = ' ' .. string.upper(key_table) .. ' ' })
  end

  -- Workspace name (if not default)
  local workspace = window:active_workspace()
  if workspace ~= 'default' then
    table.insert(cells, { Foreground = { Color = '#8aadf4' } }) -- Blue
    table.insert(cells, { Text = ' ' .. workspace .. ' ' })
  end

  window:set_right_status(wezterm.format(cells))
end)

-- ════════════════════════════════════════════════════════════════════════════
-- TAB TITLE FORMATTING (Fixed width tabs)
-- ════════════════════════════════════════════════════════════════════════════

wezterm.on('format-tab-title', function(tab, _, _, _, _, max_width)
  local title = tab.tab_title
  -- If no custom title is set, use the active pane title
  if not title or #title == 0 then
    title = tab.active_pane.title
  end

  -- Fixed width for consistent tab sizing (adjust as needed)
  local fixed_width = 28

  if #title > fixed_width then
    title = title:sub(1, fixed_width - 1) .. '…'
  else
    title = string.format('%-' .. fixed_width .. 's', title)
  end

  return {
    { Text = ' ' .. title .. ' ' },
  }
end)

-- ════════════════════════════════════════════════════════════════════════════
-- QUICK SELECT PATTERNS
-- ════════════════════════════════════════════════════════════════════════════

config.quick_select_patterns = {
  '[\\w\\-./]+\\.[a-zA-Z]+:\\d+(?::\\d+)?', -- file:line:col
  '[0-9a-f]{7,40}',                          -- git hashes
}

-- ════════════════════════════════════════════════════════════════════════════
-- MISC
-- ════════════════════════════════════════════════════════════════════════════

config.audible_bell = 'Disabled'
config.term = 'xterm-256color'

return config
