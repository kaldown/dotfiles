-- WezTerm Config - kaldown
-- Leader: CTRL+Space | Splits: |/- | Nav: CTRL+SHIFT+hjkl | Resize: Leader+r
--
-- KEYBINDINGS CHEATSHEET:
-- ═══════════════════════════════════════════════════════════════════════════
-- LEADER = CTRL+Space (1 second timeout)
--
-- SPLITS:
--   Leader + |     Split right (horizontal)
--   Leader + -     Split down (vertical)
--   Leader + z     Zoom/unzoom pane
--   Leader + x     Close pane
--   Leader + w     Visual pane selector
--
-- NAVIGATION:
--   CTRL+SHIFT + h/j/k/l    Move between panes
--
-- RESIZE MODE:
--   Leader + r     Enter resize mode
--   h/j/k/l        Resize in direction
--   Escape/q       Exit resize mode
--
-- TABS:
--   Leader + c     New tab
--   Leader + n/p   Next/prev tab
--   Leader + 1-9   Jump to tab N
--   Leader + ,     Rename tab
--   Leader + &     Close tab
--
-- WORKSPACES:
--   Leader + s     Fuzzy workspace picker
--   Leader + S     Create new workspace
--
-- UTILITIES:
--   Leader + [     Copy mode (vim-style)
--   Leader + f     Search
--   CTRL+SHIFT+P   Command palette
--   CTRL+SHIFT+Space   Quick select (URLs, paths, hashes)
-- ═══════════════════════════════════════════════════════════════════════════

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ════════════════════════════════════════════════════════════════════════════
-- APPEARANCE
-- ════════════════════════════════════════════════════════════════════════════

config.color_scheme = 'Catppuccin Macchiato'
-- config.font = wezterm.font('Hack Nerd Font Mono', { weight = 'Regular' })
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = 14.0
config.line_height = 1.2
config.cell_width = 1.0
config.freetype_load_target = 'Light' -- or 'Normal', 'HorizontalLcd'
config.freetype_render_target = 'HorizontalLcd'
config.custom_block_glyphs = false

-- Window size and position
config.initial_cols = 180
config.initial_rows = 50
config.window_decorations = 'TITLE | RESIZE'
config.window_padding = { left = 5, right = 5, top = 5, bottom = 5 }

-- M1 Pro: Enable transparency and blur
config.window_background_opacity = 0.92
config.macos_window_background_blur = 20

-- ════════════════════════════════════════════════════════════════════════════
-- TAB BAR (bottom, Catppuccin Macchiato styled)
-- ════════════════════════════════════════════════════════════════════════════

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32 -- Works with formatter to ensure consistent tab width

config.colors = {
  tab_bar = {
    background = '#1e2030',
    active_tab = {
      bg_color = '#c6a0f6', -- Mauve
      fg_color = '#1e2030',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#363a4f', -- Surface0
      fg_color = '#cad3f5', -- Text
    },
    inactive_tab_hover = {
      bg_color = '#494d64', -- Surface1
      fg_color = '#cad3f5',
    },
    new_tab = {
      bg_color = '#1e2030',
      fg_color = '#6e738d', -- Overlay0
    },
    new_tab_hover = {
      bg_color = '#494d64',
      fg_color = '#cad3f5',
    },
  },
}

-- Inactive panes slightly dimmed
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.7,
}

-- ════════════════════════════════════════════════════════════════════════════
-- PERFORMANCE
-- ════════════════════════════════════════════════════════════════════════════

config.max_fps = 120
config.animation_fps = 60
config.scrollback_lines = 10000
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
  { key = 'c', mods = 'LEADER',       action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'n', mods = 'LEADER',       action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER',       action = act.ActivateTabRelative(-1) },
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
  -- COPY/PASTE & UTILITIES
  -- ══════════════════════════════════════════════════════════════════════════
  { key = 'c',     mods = 'SUPER',      action = act.CopyTo 'Clipboard' },
  { key = 'v',     mods = 'SUPER',      action = act.PasteFrom 'Clipboard' },
  { key = '[',     mods = 'LEADER',     action = act.ActivateCopyMode },
  { key = 'f',     mods = 'LEADER',     action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 'P',     mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
  { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },

  -- ══════════════════════════════════════════════════════════════════════════
  -- ══════════════════════════════════════════════════════════════════════════
  -- FONT SIZE
  -- ══════════════════════════════════════════════════════════════════════════
  { key = '=',     mods = 'CTRL',       action = act.IncreaseFontSize },
  { key = '-',     mods = 'CTRL',       action = act.DecreaseFontSize },
  { key = '0',     mods = 'CTRL',       action = act.ResetFontSize },

  -- ══════════════════════════════════════════════════════════════════════════
  -- PRESERVED FROM ORIGINAL CONFIG
  -- ══════════════════════════════════════════════════════════════════════════
  { key = 'Enter', mods = 'SHIFT',      action = act.SendString '\x1b\r' },
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
    { key = 'Escape',     action = 'PopKeyTable' },
    { key = 'Enter',      action = 'PopKeyTable' },
    { key = 'q',          action = 'PopKeyTable' },
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

  -- Truncate if too long
  if #title > fixed_width then
    title = title:sub(1, fixed_width - 1) .. '…'
  end

  -- Pad if too short to maintain consistent width
  while #title < fixed_width do
    title = title .. ' '
  end

  return {
    { Text = ' ' .. title .. ' ' },
  }
end)

-- ════════════════════════════════════════════════════════════════════════════
-- QUICK SELECT PATTERNS (Developer-focused)
-- ════════════════════════════════════════════════════════════════════════════

config.quick_select_patterns = {
  -- File paths with line numbers (file.rs:42:15)
  '[\\w\\-./]+\\.[a-zA-Z]+:\\d+(?::\\d+)?',
  -- Git short hashes
  '[0-9a-f]{7,40}',
  -- Semantic versions
  'v?\\d+\\.\\d+\\.\\d+(?:-[a-zA-Z0-9.]+)?',
}

-- ════════════════════════════════════════════════════════════════════════════
-- HYPERLINK RULES
-- ════════════════════════════════════════════════════════════════════════════

-- Use WezTerm's default hyperlink rules as base
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Add custom rule for repository patterns (user/repo -> github.com/user/repo)
table.insert(config.hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
  format = 'https://www.github.com/$1/$3',
})

-- ════════════════════════════════════════════════════════════════════════════
-- MOUSE & CLIPBOARD
-- ════════════════════════════════════════════════════════════════════════════

-- Allow SHIFT key to bypass tmux mouse mode for text selection
-- This is the default, but we set it explicitly for clarity
config.bypass_mouse_reporting_modifiers = 'SHIFT'

config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelectionOrOpenLinkAtMouseCursor 'Clipboard',
  },
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'Clipboard',
  },
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'Clipboard',
  },
}

-- ════════════════════════════════════════════════════════════════════════════
-- MISC
-- ════════════════════════════════════════════════════════════════════════════

config.audible_bell = 'Disabled'
config.scroll_to_bottom_on_input = true
config.term = 'xterm-256color'

-- ════════════════════════════════════════════════════════════════════════════
-- STARTUP: Half screen, centered
-- ════════════════════════════════════════════════════════════════════════════

--wezterm.on('gui-startup', function(cmd)
--  local screen = wezterm.gui.screens().active
--  local ratio_w = 0.5 -- 50% of screen width
--  local ratio_h = 0.6 -- 60% of screen height
--
--  local width = math.floor(screen.width * ratio_w)
--  local height = math.floor(screen.height * ratio_h)
--  local x = math.floor((screen.width - width) / 2)
--  local y = math.floor((screen.height - height) / 2)
--
--  local tab, pane, window = wezterm.mcp.spawn_window(cmd or {})
--  window:gui_window():set_position(x, y)
--  window:gui_window():set_inner_size(width, height)
--end)

return config
