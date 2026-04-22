local M = {}

--- List all *.md decks directly under `dir` (non-recursive).
--- @param dir string absolute path to decks directory
--- @return table[] list of { name = string, path = string }
function M.list(dir)
  if vim.fn.isdirectory(dir) == 0 then
    return {}
  end

  local entries = vim.fn.readdir(dir, function(name)
    return name:sub(-3) == ".md" and 1 or 0
  end)

  local result = {}
  for _, name in ipairs(entries) do
    local full = dir .. "/" .. name
    if vim.fn.isdirectory(full) == 0 then
      table.insert(result, {
        name = name:sub(1, -4), -- strip .md
        path = full,
      })
    end
  end
  return result
end

local util = require("flashcard.util")

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  return content
end

local function split_blocks(text)
  -- A card block is delimited by a line that is exactly "---" (standalone hr).
  -- Each block records the 1-based line number of its first line in the source.
  local blocks = {}
  local current = {}
  local current_start = 1
  local lineno = 0
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    lineno = lineno + 1
    if line:match("^%-%-%-%s*$") then
      table.insert(blocks, { text = table.concat(current, "\n"), start_line = current_start })
      current = {}
      current_start = lineno + 1
    else
      table.insert(current, line)
    end
  end
  table.insert(blocks, { text = table.concat(current, "\n"), start_line = current_start })
  return blocks
end

local function split_front_back(block)
  -- A line that is exactly "?" separates front and back.
  -- Front is the last blank-line-separated paragraph before the "?" — this lets
  -- a deck file start with "# Heading\n\nintro\n\nFront question\n?\nback" and
  -- still parse the first card's front as just "Front question".
  -- Returns front, back, front_offset (1-based line index within the block of
  -- the first non-blank front line), or nil if the block has no `?`.
  local lines = {}
  for line in (block .. "\n"):gmatch("([^\n]*)\n") do
    table.insert(lines, line)
  end

  local sep_idx
  for i, line in ipairs(lines) do
    if line:match("^%?%s*$") then
      sep_idx = i
      break
    end
  end
  if not sep_idx then
    return nil
  end

  local front_start = 1
  for i = sep_idx - 1, 1, -1 do
    if lines[i]:match("^%s*$") then
      front_start = i + 1
      break
    end
  end

  local front_buf = {}
  for i = front_start, sep_idx - 1 do
    table.insert(front_buf, lines[i])
  end
  local back_buf = {}
  for i = sep_idx + 1, #lines do
    table.insert(back_buf, lines[i])
  end

  return util.trim(table.concat(front_buf, "\n")),
    util.trim(table.concat(back_buf, "\n")),
    front_start
end

--- Parse a markdown deck file into cards.
--- @param path string absolute path to the .md file
--- @return table result { cards = [{id, front, back}], warnings = [], err = string? }
function M.parse(path)
  local content = read_file(path)
  if not content then
    return { err = "cannot read deck file: " .. path, cards = {}, warnings = {} }
  end

  local cards = {}
  local warnings = {}
  for _, block in ipairs(split_blocks(content)) do
    local front, back, front_offset = split_front_back(block.text)
    if not front then
      -- no `?` separator: either intro text before first card or malformed
      local trimmed = util.trim(block.text)
      if trimmed ~= "" and #cards > 0 then
        -- we've already started cards, so this is a malformed card
        table.insert(warnings, "card has no `?` separator")
      end
      -- otherwise: silent intro; skip
    elseif front == "" or back == "" then
      table.insert(
        warnings,
        "card has empty front or back (front=" .. #front .. " back=" .. #back .. ")"
      )
    else
      table.insert(cards, {
        id = util.hash(front),
        front = front,
        back = back,
        front_line = block.start_line + front_offset - 1,
      })
    end
  end

  if #cards == 0 then
    return { err = "no valid cards found in " .. path, cards = {}, warnings = warnings }
  end

  return { cards = cards, warnings = warnings }
end

return M
