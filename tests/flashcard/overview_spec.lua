local overview = require("flashcard.overview")

local function card(id, front, front_line)
  return { id = id, front = front, back = "b", front_line = front_line or 1 }
end

describe("overview.build_rows", function()
  it("returns an empty array for an empty deck", function()
    assert.same({}, overview.build_rows({}, {}, "2026-04-22"))
  end)

  it("classifies every card as 'new' when state is empty", function()
    local cards = { card("a", "A", 1), card("b", "B", 5) }
    local rows = overview.build_rows(cards, {}, "2026-04-22")
    assert.equals(2, #rows)
    assert.equals("new", rows[1].status)
    assert.equals("new", rows[2].status)
    assert.is_nil(rows[1].last_reviewed)
    assert.is_nil(rows[2].last_reviewed)
  end)

  it("puts never-reviewed cards ahead of reviewed ones", function()
    local cards = { card("rev", "R", 1), card("new", "N", 5) }
    local st = {
      rev = { ease = 2.5, interval = 1, reps = 1, due = "2026-04-30", last_reviewed = "2026-04-20" },
    }
    local rows = overview.build_rows(cards, st, "2026-04-22")
    assert.equals("new", rows[1].id)
    assert.equals("rev", rows[2].id)
  end)

  it("classifies 'due' when due <= today", function()
    local cards = { card("a", "A") }
    local st = {
      a = { ease = 2.5, interval = 1, reps = 1, due = "2026-04-22", last_reviewed = "2026-04-20" },
    }
    local rows = overview.build_rows(cards, st, "2026-04-22")
    assert.equals("due", rows[1].status)
  end)

  it("classifies 'scheduled' when due > today", function()
    local cards = { card("a", "A") }
    local st = {
      a = { ease = 2.5, interval = 5, reps = 2, due = "2026-04-30", last_reviewed = "2026-04-20" },
    }
    local rows = overview.build_rows(cards, st, "2026-04-22")
    assert.equals("scheduled", rows[1].status)
  end)

  it("sorts reviewed cards oldest last_reviewed first", function()
    local cards = { card("recent", "R"), card("older", "O"), card("oldest", "X") }
    local st = {
      recent = {
        ease = 2.5,
        interval = 1,
        reps = 1,
        due = "2026-04-30",
        last_reviewed = "2026-04-21",
      },
      older = {
        ease = 2.5,
        interval = 1,
        reps = 1,
        due = "2026-04-30",
        last_reviewed = "2026-04-15",
      },
      oldest = {
        ease = 2.5,
        interval = 1,
        reps = 1,
        due = "2026-04-30",
        last_reviewed = "2026-04-01",
      },
    }
    local rows = overview.build_rows(cards, st, "2026-04-22")
    assert.equals("oldest", rows[1].id)
    assert.equals("older", rows[2].id)
    assert.equals("recent", rows[3].id)
  end)

  it("breaks last_reviewed ties by original deck order", function()
    local cards = { card("first", "F"), card("second", "S") }
    local st = {
      first = {
        ease = 2.5,
        interval = 1,
        reps = 1,
        due = "2026-04-30",
        last_reviewed = "2026-04-20",
      },
      second = {
        ease = 2.5,
        interval = 1,
        reps = 1,
        due = "2026-04-30",
        last_reviewed = "2026-04-20",
      },
    }
    local rows = overview.build_rows(cards, st, "2026-04-22")
    assert.equals("first", rows[1].id)
    assert.equals("second", rows[2].id)
  end)

  it("breaks ties between never-reviewed cards by deck order", function()
    local cards = { card("a", "A"), card("b", "B") }
    local rows = overview.build_rows(cards, {}, "2026-04-22")
    assert.equals("a", rows[1].id)
    assert.equals("b", rows[2].id)
  end)

  it("collapses newlines in front_preview to single spaces", function()
    local cards = { card("a", "line one\nline two\n\nline three") }
    local rows = overview.build_rows(cards, {}, "2026-04-22")
    assert.equals("line one line two  line three", rows[1].front_preview)
  end)

  it("propagates front_line from the input card", function()
    local cards = { card("a", "A", 42) }
    local rows = overview.build_rows(cards, {}, "2026-04-22")
    assert.equals(42, rows[1].front_line)
  end)
end)
