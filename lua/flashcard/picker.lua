local M = {}

local function has_telescope()
  return pcall(require, "telescope")
end

--- Show a picker over the given decks. Calls `on_select(deck)` with the chosen
--- deck (as returned by deck.list), or does nothing on cancel.
--- @param decks table[]   list of { name, path } from deck.list
--- @param on_select fun(deck: table)
function M.pick(decks, on_select)
  if #decks == 0 then
    vim.notify("[flashcard] no decks found", vim.log.levels.WARN)
    return
  end

  if has_telescope() then
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers
      .new({}, {
        prompt_title = "flashcard decks",
        finder = finders.new_table({
          results = decks,
          entry_maker = function(d)
            return { value = d, display = d.name, ordinal = d.name }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(bufnr)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(bufnr)
            if selection then
              on_select(selection.value)
            end
          end)
          return true
        end,
      })
      :find()
  else
    local names = {}
    for _, d in ipairs(decks) do
      table.insert(names, d.name)
    end
    vim.ui.select(names, { prompt = "flashcard decks" }, function(_, idx)
      if idx then
        on_select(decks[idx])
      end
    end)
  end
end

return M
