local M = {}

local ns = vim.api.nvim_create_namespace("flashcard_ui_overview")

local COL_LAST = 13 -- "2026-04-22" + 3 padding, accommodates "never"
local COL_STATUS = 12 -- "scheduled" + padding

local function center_size(frac_w, frac_h)
  local columns = vim.o.columns
  local lines = vim.o.lines
  local w = math.floor(columns * frac_w)
  local h = math.floor(lines * frac_h)
  local row = math.floor((lines - h) / 2)
  local col = math.floor((columns - w) / 2)
  return w, h, row, col
end

local function open_float(cfg, title)
  local w, h, row, col = center_size(cfg.window.width, cfg.window.height)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "flashcard-overview"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = row,
    col = col,
    border = cfg.window.border,
    style = "minimal",
    title = title,
    title_pos = "center",
  })

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  return buf, win, w
end

local function pad(s, n)
  if #s >= n then
    return s
  end
  return s .. string.rep(" ", n - #s)
end

local function truncate(s, n)
  if n <= 0 then
    return ""
  end
  if #s <= n then
    return s
  end
  if n <= 1 then
    return "…"
  end
  return s:sub(1, n - 1) .. "…"
end

local function counts(rows)
  local c = { due = 0, new = 0, scheduled = 0 }
  for _, r in ipairs(rows) do
    c[r.status] = (c[r.status] or 0) + 1
  end
  return c
end

local function header_line(deck_name, rows)
  local c = counts(rows)
  return string.format(
    "  %s — %d cards (%d due, %d new, %d scheduled)",
    deck_name,
    #rows,
    c.due,
    c.new,
    c.scheduled
  )
end

local function column_header()
  return "  " .. pad("LAST REVIEWED", COL_LAST) .. pad("STATUS", COL_STATUS) .. "FRONT"
end

local function row_line(row, front_width)
  local last = row.last_reviewed or "never"
  local front = truncate(row.front_preview, front_width)
  return "  " .. pad(last, COL_LAST) .. pad(row.status, COL_STATUS) .. front
end

local function footer_line()
  return "  j/k: move   <CR>: open card   q: close"
end

--- Render rows in a floating window.
---
--- @param cfg table       merged config
--- @param ctx table       { deck_name, rows, on_select(row) }
function M.run(cfg, ctx)
  local title = string.format(" overview: %s ", ctx.deck_name)
  local buf, win, win_w = open_float(cfg, title)

  local front_width = win_w - (2 + COL_LAST + COL_STATUS)

  local lines = {}
  table.insert(lines, header_line(ctx.deck_name, ctx.rows))
  table.insert(lines, "")
  table.insert(lines, column_header())

  local data_start = #lines + 1 -- 1-based line number of first data row
  for _, row in ipairs(ctx.rows) do
    table.insert(lines, row_line(row, front_width))
  end

  table.insert(lines, "")
  table.insert(lines, footer_line())

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Highlight the column-header row.
  local hdr_idx = data_start - 2 -- 0-based index of column header line
  vim.api.nvim_buf_set_extmark(buf, ns, hdr_idx, 0, {
    end_col = #lines[hdr_idx + 1],
    hl_group = "FlashcardKey",
  })
  vim.bo[buf].modifiable = false

  -- Place cursor on the first data row (or the header if no rows).
  local initial_line = math.min(data_start, #lines)
  if #ctx.rows == 0 then
    initial_line = 1
  end
  pcall(vim.api.nvim_win_set_cursor, win, { initial_line, 0 })

  local function close_window()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function select_current()
    local cur = vim.api.nvim_win_get_cursor(win)[1]
    local idx = cur - data_start + 1
    local row = ctx.rows[idx]
    if not row then
      return -- header or footer
    end
    close_window()
    ctx.on_select(row)
  end

  local function set_key(key, fn)
    vim.keymap.set("n", key, fn, { buffer = buf, nowait = true, silent = true })
  end

  set_key("<CR>", select_current)
  set_key(cfg.keymaps.quit, close_window)
end

return M
