local util = require("flashcard.util")

local M = {}

local EASE_FLOOR = 1.3

local function clamp_ease(e)
  if e < EASE_FLOOR then
    return EASE_FLOOR
  end
  return e
end

local function round(x)
  return math.floor(x + 0.5)
end

--- Apply an SM-2 rating to a card's scheduling state.
--- @param state table { ease, interval, reps }
--- @param rating integer 1=Again, 2=Hard, 3=Good, 4=Easy
--- @param today string ISO date "YYYY-MM-DD"
--- @return table new_state { ease, interval, reps, due, last_reviewed }
function M.rate(state, rating, today)
  local ease = state.ease
  local interval = state.interval
  local reps = state.reps

  if rating == 1 then
    reps = 0
    interval = 1
    ease = clamp_ease(ease - 0.2)
  else
    if reps == 0 then
      interval = 1
    elseif reps == 1 then
      interval = 6
    else
      interval = round(interval * ease)
    end

    if rating == 2 then
      ease = clamp_ease(ease - 0.15)
    elseif rating == 4 then
      ease = ease + 0.15
    end
    -- rating == 3 (Good) leaves ease unchanged

    reps = reps + 1
  end

  return {
    ease = ease,
    interval = interval,
    reps = reps,
    due = util.add_days(today, interval),
    last_reviewed = today,
  }
end

return M
