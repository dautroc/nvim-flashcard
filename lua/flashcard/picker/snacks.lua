local M = {}

function M.is_available()
  return pcall(require, "snacks.picker")
end

--- @param items      table[]   list of { name, path }
--- @param opts       { prompt: string }
--- @param on_choose  fun(item: table)
function M.pick(items, opts, on_choose)
  require("snacks.picker").pick({
    source = "flashcard_decks",
    items = items,
    format = function(item)
      return { { item.name, "Normal" } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        on_choose(item)
      end
    end,
    title = opts.prompt,
  })
end

return M
