local M = {}

local api = vim.api
local render

local state = {
  buf = nil,
  win = nil,
  line_to_term = {},
  timer = nil,
}

local ignored_commands = {
  ["bash"] = true,
  ["sh"] = true,
  ["zsh"] = true,
  ["fish"] = true,
  ["tmux"] = true,
  ["login"] = true,
}

local function get_terminals()
  return require("toggleterm.terminal").get_all(true)
end

local function panel_open()
  return state.win and api.nvim_win_is_valid(state.win)
end

local function stop_timer()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

local function start_timer()
  stop_timer()
  state.timer = vim.uv.new_timer()
  if not state.timer then
    return
  end

  state.timer:start(0, 1000, vim.schedule_wrap(function()
    if panel_open() then
      render()
    else
      stop_timer()
    end
  end))
end

local function truncate(text, max_len)
  if #text <= max_len then
    return text
  end
  return text:sub(1, max_len - 3) .. "..."
end

local function term_tty(term)
  if not term.job_id then
    return nil
  end

  local pid = vim.fn.jobpid(term.job_id)
  if not pid or pid <= 0 then
    return nil
  end

  local tty = vim.trim(vim.fn.system({ "ps", "-o", "tty=", "-p", tostring(pid) }))
  if vim.v.shell_error ~= 0 or tty == "" or tty == "?" then
    return nil
  end

  return tty
end

local function running_task(term)
  local tty = term_tty(term)
  if not tty then
    return "idle"
  end

  local output = vim.fn.system({ "ps", "-o", "state=,pgid=,tpgid=,comm=,args=", "-t", tty })
  if vim.v.shell_error ~= 0 then
    return "idle"
  end

  local active = nil
  for line in output:gmatch("[^\r\n]+") do
    local state_code, pgid, tpgid, comm, args = line:match("^%s*(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(.*)$")
    if state_code and pgid == tpgid and comm and not ignored_commands[comm] and not state_code:match("^[TXZ]") then
      active = args ~= "" and args or comm
    end
  end

  return active and truncate(active, 60) or "idle"
end

local function format_term(term)
  local name = term:_display_name()
  return string.format("%d. %-18s %s", term.id, truncate(name, 18), running_task(term))
end

render = function()
  if not (state.buf and api.nvim_buf_is_valid(state.buf)) then
    return
  end

  local lines = {
    "<CR>/o open or focus   a add   r rename   d delete   q close",
    "",
  }

  state.line_to_term = {}

  local terms = get_terminals()
  if vim.tbl_isempty(terms) then
    table.insert(lines, "  No terminals yet. Press a to create one.")
  else
    for _, term in ipairs(terms) do
      table.insert(lines, format_term(term))
      state.line_to_term[#lines] = term.id
    end
  end

  api.nvim_buf_set_option(state.buf, "modifiable", true)
  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  api.nvim_buf_set_option(state.buf, "modifiable", false)
end

local function refresh()
  if panel_open() then
    render()
  end
end

local function current_term()
  local line = api.nvim_win_get_cursor(state.win)[1]
  local term_id = state.line_to_term[line]
  if not term_id then
    return nil
  end
  return require("toggleterm.terminal").get(term_id, true)
end

local function close_panel()
  if panel_open() then
    api.nvim_win_close(state.win, true)
  end
  stop_timer()
  state.win = nil
  state.buf = nil
end

local function open_term(term)
  if not term then
    return
  end

  if term:is_open() then
    term:focus()
  else
    term:toggle()
  end
  refresh()
end

local function add_term()
  vim.ui.input({ prompt = "Terminal name: " }, function(input)
    if input == nil then
      refresh()
      return
    end

    local Terminal = require("toggleterm.terminal").Terminal
    local name = input ~= "" and input or nil
    local term = Terminal:new({
      direction = "float",
      dir = vim.uv.cwd(),
      hidden = false,
      close_on_exit = false,
      display_name = name,
    })

    term:toggle()
    refresh()
  end)
end

local function rename_term()
  local term = current_term()
  if not term then
    return
  end

  vim.ui.input({ prompt = "Rename terminal: ", default = term:_display_name() }, function(input)
    if input == nil then
      refresh()
      return
    end

    term.display_name = input ~= "" and input or nil
    refresh()
  end)
end

local function delete_term()
  local term = current_term()
  if not term then
    return
  end

  local choice = vim.fn.confirm("Delete terminal " .. term.id .. "?", "&Yes\n&No", 2)
  if choice ~= 1 then
    refresh()
    return
  end

  term:shutdown()
  refresh()
end

local function open_panel()
  if panel_open() then
    close_panel()
    return
  end

  state.buf = api.nvim_create_buf(false, true)
  vim.cmd("botright 10split")
  state.win = api.nvim_get_current_win()
  api.nvim_win_set_buf(state.win, state.buf)

  pcall(api.nvim_buf_set_name, state.buf, "Terminal Manager")
  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.buf].buflisted = false
  vim.bo[state.buf].readonly = false
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].filetype = "terminal-manager"
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].winfixheight = true
  vim.wo[state.win].cursorline = true
  vim.wo[state.win].winbar = ""

  local opts = { buffer = state.buf, noremap = true, silent = true }
  vim.keymap.set("n", "q", close_panel, opts)
  vim.keymap.set("n", "<CR>", function() open_term(current_term()) end, opts)
  vim.keymap.set("n", "o", function() open_term(current_term()) end, opts)
  vim.keymap.set("n", "a", add_term, opts)
  vim.keymap.set("n", "r", rename_term, opts)
  vim.keymap.set("n", "d", delete_term, opts)

  render()
  start_timer()
end

function M.toggle_panel()
  open_panel()
end

function M.add_term()
  add_term()
end

function M.rename_term()
  if panel_open() then
    rename_term()
  else
    local terms = get_terminals()
    if #terms == 0 then
      return
    end
    vim.ui.select(terms, {
      prompt = "Rename terminal",
      format_item = function(term)
        return string.format("%d: %s", term.id, term:_display_name())
      end,
    }, function(term)
      if term then
        vim.ui.input({ prompt = "Rename terminal: ", default = term:_display_name() }, function(input)
          if input == nil then
            return
          end
          term.display_name = input ~= "" and input or nil
          refresh()
        end)
      end
    end)
  end
end

function M.delete_term()
  if panel_open() then
    delete_term()
  else
    local terms = get_terminals()
    if #terms == 0 then
      return
    end
    vim.ui.select(terms, {
      prompt = "Delete terminal",
      format_item = function(term)
        return string.format("%d: %s", term.id, term:_display_name())
      end,
    }, function(term)
      if term then
        local choice = vim.fn.confirm("Delete terminal " .. term.id .. "?", "&Yes\n&No", 2)
        if choice == 1 then
          term:shutdown()
          refresh()
        end
      end
    end)
  end
end

function M.setup()
  local group = api.nvim_create_augroup("TerminalManager", { clear = true })
  api.nvim_create_autocmd({ "TermOpen", "TermClose", "BufEnter" }, {
    group = group,
    callback = function()
      vim.schedule(refresh)
    end,
  })
end

return M
