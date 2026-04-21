local M = {}

--- Choose the next card to show in a review session.
--- Priority 1: cards with a state entry whose `due <= today` (review + lapsed).
---             Oldest `due` first; ties broken by deck order.
--- Priority 2: cards with no state entry (brand-new), in deck order, capped by budget.
---
--- @param cards table[]   list of { id, front, back } from deck.parse
--- @param st table        map of card-id -> state row (from state.load)
--- @param today string    ISO "YYYY-MM-DD"
--- @param new_budget integer remaining new-card budget for this session
--- @return table|nil card next card to show, or nil if session is done
function M.next_due(cards, st, today, new_budget)
  local due_reviews = {}
  local first_new

  for _, card in ipairs(cards) do
    local row = st[card.id]
    if row then
      -- ISO dates compare lexicographically as calendar dates
      if row.due <= today then
        table.insert(due_reviews, { card = card, due = row.due })
      end
    else
      if not first_new then
        first_new = card
      end
    end
  end

  if #due_reviews > 0 then
    table.sort(due_reviews, function(a, b)
      return a.due < b.due
    end)
    return due_reviews[1].card
  end

  if first_new and new_budget > 0 then
    return first_new
  end

  return nil
end

return M
