if vim.g.loaded_flashcard == 1 then
  return
end
vim.g.loaded_flashcard = 1

vim.api.nvim_create_user_command("Flashcard", function(opts)
  require("flashcard").start(opts.args)
end, {
  nargs = "?",
  desc = "Start a flashcard review session (optionally on a specific deck)",
  complete = function(arg_lead)
    local names = require("flashcard")._deck_names()
    local matches = {}
    for _, n in ipairs(names) do
      if n:find(arg_lead, 1, true) == 1 then
        table.insert(matches, n)
      end
    end
    return matches
  end,
})
