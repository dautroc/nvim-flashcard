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

return M
