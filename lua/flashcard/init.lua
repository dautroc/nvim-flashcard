local config_mod = require("flashcard.config")
local deck_mod = require("flashcard.deck")
local state_mod = require("flashcard.state")
local srs_mod = require("flashcard.srs")
local scheduler_mod = require("flashcard.scheduler")
local picker_mod = require("flashcard.picker")
local ui_mod = require("flashcard.ui")
local util = require("flashcard.util")

local M = {}

local cfg

--- Merge user options over defaults. Call once from user config.
function M.setup(opts)
  cfg = config_mod.setup(opts)
end

local function ensure_cfg()
  if not cfg then
    cfg = config_mod.setup(nil)
  end
  return cfg
end

local function new_card_defaults(today)
  return { ease = 2.5, interval = 0, reps = 0, due = today, last_reviewed = nil }
end

local function start_session(deck_info)
  local parsed = deck_mod.parse(deck_info.path)
  if parsed.err then
    vim.notify("[flashcard] " .. parsed.err, vim.log.levels.ERROR)
    return
  end
  for _, w in ipairs(parsed.warnings or {}) do
    vim.notify("[flashcard] " .. deck_info.name .. ": " .. w, vim.log.levels.WARN)
  end

  local today = util.today()
  local st = state_mod.load(deck_info.path)
  local budget = cfg.new_cards_per_day

  -- Compute expected session size up front so the UI can show "Card N of M"
  -- based on this session rather than the whole deck.
  local due_count, new_count = 0, 0
  for _, c in ipairs(parsed.cards) do
    local row = st[c.id]
    if row then
      if row.due <= today then
        due_count = due_count + 1
      end
    else
      new_count = new_count + 1
    end
  end
  local total = due_count + math.min(new_count, budget)
  local seen_this_session = 0

  local function next_card()
    local card = scheduler_mod.next_due(parsed.cards, st, today, budget)
    if not card then
      return nil
    end
    if not st[card.id] then
      budget = budget - 1
    end
    seen_this_session = seen_this_session + 1
    return { card = card, index = seen_this_session, total = total }
  end

  local function rate(card, rating)
    local prev = st[card.id] or new_card_defaults(today)
    st[card.id] = srs_mod.rate(prev, rating, today)
    local ok, err = pcall(state_mod.save, deck_info.path, st)
    if not ok then
      vim.notify("[flashcard] state save failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end

  ui_mod.run(cfg, {
    next = next_card,
    rate = rate,
    on_close = function() end,
  })
end

--- Start a review session. If `deck_name` is given, skip the picker.
function M.start(deck_name)
  ensure_cfg()
  local decks = deck_mod.list(cfg.decks_dir)
  if #decks == 0 then
    vim.notify("[flashcard] no decks found at " .. cfg.decks_dir, vim.log.levels.WARN)
    return
  end

  if deck_name and deck_name ~= "" then
    for _, d in ipairs(decks) do
      if d.name == deck_name then
        start_session(d)
        return
      end
    end
    vim.notify("[flashcard] deck not found: " .. deck_name, vim.log.levels.ERROR)
    return
  end

  picker_mod.pick(decks, { prompt = "Study deck", cfg = cfg }, start_session)
end

--- Alias: the canonical name going forward is `learn`. `start` is preserved
--- for any existing external callers.
M.learn = M.start

--- Internal: list deck names (for :Flashcard tab completion).
function M._deck_names()
  ensure_cfg()
  local out = {}
  for _, d in ipairs(deck_mod.list(cfg.decks_dir)) do
    table.insert(out, d.name)
  end
  return out
end

return M
