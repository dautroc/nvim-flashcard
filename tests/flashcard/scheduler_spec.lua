local scheduler = require("flashcard.scheduler")

local function card(id, front)
  return { id = id, front = front, back = "b" }
end

describe("scheduler.next_due", function()
  it("returns nil for an empty deck", function()
    assert.is_nil(scheduler.next_due({}, {}, "2026-04-21", 20))
  end)

  it("returns a review card that is due today", function()
    local cards = { card("a", "A"), card("b", "B") }
    local st = {
      a = { ease = 2.5, interval = 1, reps = 1, due = "2026-04-21", last_reviewed = "2026-04-20" },
      b = { ease = 2.5, interval = 5, reps = 2, due = "2026-04-25", last_reviewed = "2026-04-20" },
    }
    local next = scheduler.next_due(cards, st, "2026-04-21", 20)
    assert.equals("a", next.id)
  end)

  it("returns the oldest-due review card first", function()
    local cards = { card("a", "A"), card("b", "B") }
    local st = {
      a = { ease = 2.5, interval = 1, reps = 1, due = "2026-04-20", last_reviewed = "2026-04-19" },
      b = { ease = 2.5, interval = 1, reps = 1, due = "2026-04-18", last_reviewed = "2026-04-17" },
    }
    local next = scheduler.next_due(cards, st, "2026-04-21", 20)
    assert.equals("b", next.id)
  end)

  it("returns a lapsed card (reps=0, due today, in state)", function()
    local cards = { card("a", "A") }
    local st = {
      a = { ease = 2.3, interval = 1, reps = 0, due = "2026-04-21", last_reviewed = "2026-04-20" },
    }
    local next = scheduler.next_due(cards, st, "2026-04-21", 20)
    assert.equals("a", next.id)
  end)

  it("returns a new card when no reviews are due and budget > 0", function()
    local cards = { card("new1", "N1"), card("new2", "N2") }
    local next = scheduler.next_due(cards, {}, "2026-04-21", 20)
    assert.equals("new1", next.id)
  end)

  it("returns reviews before new cards", function()
    local cards = { card("new1", "N1"), card("rev", "R") }
    local st = {
      rev = { ease = 2.5, interval = 1, reps = 1, due = "2026-04-21", last_reviewed = "2026-04-20" },
    }
    local next = scheduler.next_due(cards, st, "2026-04-21", 20)
    assert.equals("rev", next.id)
  end)

  it("does not return new cards when budget is 0", function()
    local cards = { card("new1", "N1") }
    assert.is_nil(scheduler.next_due(cards, {}, "2026-04-21", 0))
  end)

  it("returns nil when all reviews are in the future and no budget", function()
    local cards = { card("a", "A") }
    local st = {
      a = { ease = 2.5, interval = 10, reps = 3, due = "2026-05-01", last_reviewed = "2026-04-21" },
    }
    assert.is_nil(scheduler.next_due(cards, st, "2026-04-21", 20))
  end)
end)
