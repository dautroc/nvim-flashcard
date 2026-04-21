local M = {}

local function center_size(frac_w, frac_h)
  local columns = vim.o.columns
  local lines = vim.o.lines
  local w = math.floor(columns * frac_w)
  local h = math.floor(lines * frac_h)
  local row = math.floor((lines - h) / 2)
  local col = math.floor((columns - w) / 2)
  return w, h, row, col
end

local function open_float(cfg)
  local w, h, row, col = center_size(cfg.window.width, cfg.window.height)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = row,
    col = col,
    border = cfg.window.border,
    style = "minimal",
    title = " flashcard ",
    title_pos = "center",
  })

  vim.wo[win].wrap = true
  vim.wo[win].cursorline = false
  return buf, win
end

local function render(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function split_lines(text)
  local out = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    table.insert(out, line)
  end
  return out
end

local function front_lines(card, index, total)
  local header = string.format("  Card %d of %d — press <Space> to reveal", index, total)
  local lines = { header, "" }
  for _, l in ipairs(split_lines(card.front)) do
    table.insert(lines, l)
  end
  return lines
end

local function both_lines(card, index, total)
  local header = string.format("  Card %d of %d — 1:Again  2:Hard  3:Good  4:Easy", index, total)
  local lines = { header, "" }
  for _, l in ipairs(split_lines(card.front)) do
    table.insert(lines, l)
  end
  table.insert(lines, "")
  table.insert(lines, "  ---")
  table.insert(lines, "")
  for _, l in ipairs(split_lines(card.back)) do
    table.insert(lines, l)
  end
  return lines
end

local function completion_lines(reviewed)
  return {
    "",
    string.format("  Session complete — %d reviewed", reviewed),
    "",
    "  Press q to close.",
  }
end

--- Run a review session loop.
--- Callbacks:
---   next()           -> { card = card, index = int, total = int } or nil
---   rate(card, r)    -> apply SM-2 rating, persist state
---   on_close()       -> called when the session window closes
---
--- @param cfg table   the merged config
--- @param hooks table { next, rate, on_close }
function M.run(cfg, hooks)
  local buf, win = open_float(cfg)
  local reviewed = 0
  local revealed = false
  local current -- { card, index, total }

  local function close_window()
    -- on_close is fired by the WinClosed/BufWipeout autocmd below; don't double-call here
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function advance()
    current = hooks.next()
    revealed = false
    if current then
      render(buf, front_lines(current.card, current.index, current.total))
    else
      render(buf, completion_lines(reviewed))
    end
  end

  local function reveal()
    if current and not revealed then
      revealed = true
      render(buf, both_lines(current.card, current.index, current.total))
    end
  end

  local function rate(rating)
    if current and revealed then
      hooks.rate(current.card, rating)
      reviewed = reviewed + 1
      advance()
    end
  end

  local function set_key(key, fn)
    vim.keymap.set("n", key, fn, { buffer = buf, nowait = true, silent = true })
  end

  set_key(cfg.keymaps.reveal, reveal)
  set_key(cfg.keymaps.again, function()
    rate(1)
  end)
  set_key(cfg.keymaps.hard, function()
    rate(2)
  end)
  set_key(cfg.keymaps.good, function()
    rate(3)
  end)
  set_key(cfg.keymaps.easy, function()
    rate(4)
  end)
  set_key(cfg.keymaps.quit, close_window)

  vim.api.nvim_create_autocmd({ "BufWipeout", "WinClosed" }, {
    buffer = buf,
    once = true,
    callback = function()
      if hooks.on_close then
        hooks.on_close()
      end
    end,
  })

  advance()
end

return M
