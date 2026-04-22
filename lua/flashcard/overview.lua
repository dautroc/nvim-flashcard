local M = {}

local function preview(text)
  return (text:gsub("\n", " "))
end

local function classify(state_row, today)
  if not state_row then
    return "new"
  end
  if state_row.due <= today then
    return "due"
  end
  return "scheduled"
end

--- Build sorted overview rows for a deck.
--- Sort: primary key `last_reviewed` ascending (nil treated as smallest);
--- tiebreaker is the card's position in the input array (deck order).
---
--- @param cards table[]   list of { id, front, back, front_line } from deck.parse
--- @param st table        map of card-id -> state row (from state.load)
--- @param today string    ISO "YYYY-MM-DD"
--- @return table[] rows   [{ id, last_reviewed, status, front_preview, front_line }]
function M.build_rows(cards, st, today)
  local rows = {}
  for i, card in ipairs(cards) do
    local row = st[card.id]
    table.insert(rows, {
      id = card.id,
      last_reviewed = row and row.last_reviewed or nil,
      status = classify(row, today),
      front_preview = preview(card.front),
      front_line = card.front_line,
      _order = i,
    })
  end

  table.sort(rows, function(a, b)
    local la = a.last_reviewed or ""
    local lb = b.last_reviewed or ""
    if la ~= lb then
      return la < lb
    end
    return a._order < b._order
  end)

  for _, r in ipairs(rows) do
    r._order = nil
  end
  return rows
end

return M
