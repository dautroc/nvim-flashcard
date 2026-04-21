local M = {}

function M.is_available()
  return true
end

--- @param items table[]   list of { name, path }
--- @param opts  { prompt: string }
--- @param on_choose fun(item: table)
function M.pick(items, opts, on_choose)
  local names = {}
  for _, it in ipairs(items) do
    table.insert(names, it.name)
  end
  vim.ui.select(names, { prompt = opts.prompt }, function(_, idx)
    if idx then
      on_choose(items[idx])
    end
  end)
end

return M
