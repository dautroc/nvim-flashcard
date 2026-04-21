local M = {}

-- Adapter registry. Exposed via _set_adapters for unit testing; production
-- code never mutates this table at runtime.
local adapters = {
  snacks = require("flashcard.picker.snacks"),
  telescope = require("flashcard.picker.telescope"),
  select = require("flashcard.picker.select"),
}

-- Auto-detect order when cfg.picker is nil.
local auto_order = { "snacks", "telescope", "select" }

--- Test-only: replace the adapter table.
function M._set_adapters(new_adapters)
  adapters = new_adapters
end

local function resolve(cfg_picker)
  if type(cfg_picker) == "function" then
    return cfg_picker
  end

  if type(cfg_picker) == "string" then
    local a = adapters[cfg_picker]
    if a and a.is_available() then
      return a.pick
    end
    vim.notify(
      "[flashcard] configured picker '"
        .. cfg_picker
        .. "' is unavailable; falling back to vim.ui.select",
      vim.log.levels.ERROR
    )
    return adapters.select.pick
  end

  -- nil: auto-detect
  for _, name in ipairs(auto_order) do
    local a = adapters[name]
    if a and a.is_available() then
      return a.pick
    end
  end
  return adapters.select.pick
end

--- Show a picker over items and invoke on_choose with the selection.
--- @param items      table[]   list of { name, path }
--- @param opts       { prompt: string, cfg: table }
--- @param on_choose  fun(item: table)
function M.pick(items, opts, on_choose)
  if #items == 0 then
    vim.notify("[flashcard] no decks to show", vim.log.levels.WARN)
    return
  end
  local pick_fn = resolve(opts.cfg and opts.cfg.picker)
  pick_fn(items, opts, on_choose)
end

return M
