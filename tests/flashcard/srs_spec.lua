local srs = require("flashcard.srs")

local function new_card()
  return { ease = 2.5, interval = 0, reps = 0 }
end

describe("srs.rate — Again (1)", function()
  it("resets reps to 0 and interval to 1", function()
    local s = { ease = 2.5, interval = 20, reps = 5 }
    local out = srs.rate(s, 1, "2026-04-21")
    assert.equals(0, out.reps)
    assert.equals(1, out.interval)
  end)

  it("reduces ease by 0.2", function()
    local s = { ease = 2.5, interval = 20, reps = 5 }
    local out = srs.rate(s, 1, "2026-04-21")
    assert.equals(2.3, out.ease)
  end)

  it("does not drop ease below 1.3", function()
    local s = { ease = 1.35, interval = 1, reps = 1 }
    local out = srs.rate(s, 1, "2026-04-21")
    assert.equals(1.3, out.ease)
  end)

  it("schedules due tomorrow", function()
    local s = new_card()
    local out = srs.rate(s, 1, "2026-04-21")
    assert.equals("2026-04-22", out.due)
    assert.equals("2026-04-21", out.last_reviewed)
  end)
end)

describe("srs.rate — Good (3)", function()
  it("first review sets interval=1 and reps=1", function()
    local out = srs.rate(new_card(), 3, "2026-04-21")
    assert.equals(1, out.interval)
    assert.equals(1, out.reps)
    assert.equals(2.5, out.ease)
    assert.equals("2026-04-22", out.due)
  end)

  it("second review sets interval=6 and reps=2", function()
    local s = { ease = 2.5, interval = 1, reps = 1 }
    local out = srs.rate(s, 3, "2026-04-21")
    assert.equals(6, out.interval)
    assert.equals(2, out.reps)
    assert.equals("2026-04-27", out.due)
  end)

  it("subsequent review multiplies interval by ease", function()
    local s = { ease = 2.5, interval = 6, reps = 2 }
    local out = srs.rate(s, 3, "2026-04-21")
    assert.equals(15, out.interval) -- round(6 * 2.5) = 15
    assert.equals(3, out.reps)
  end)
end)

describe("srs.rate — Hard (2)", function()
  it("reduces ease by 0.15 but uses same interval progression as Good", function()
    local s = { ease = 2.5, interval = 6, reps = 2 }
    local out = srs.rate(s, 2, "2026-04-21")
    assert.equals(2.35, out.ease)
    assert.equals(15, out.interval) -- round(6 * 2.5) still; ease applies next round
    assert.equals(3, out.reps)
  end)

  it("does not drop ease below 1.3", function()
    local s = { ease = 1.4, interval = 10, reps = 3 }
    local out = srs.rate(s, 2, "2026-04-21")
    assert.equals(1.3, out.ease)
  end)
end)

describe("srs.rate — Easy (4)", function()
  it("increases ease by 0.15", function()
    local s = { ease = 2.5, interval = 6, reps = 2 }
    local out = srs.rate(s, 4, "2026-04-21")
    assert.equals(2.65, out.ease)
    assert.equals(3, out.reps)
  end)
end)

describe("srs.rate — rounding", function()
  it("rounds interval*ease to nearest integer", function()
    local s = { ease = 2.3, interval = 7, reps = 3 }
    local out = srs.rate(s, 3, "2026-04-21")
    assert.equals(16, out.interval) -- round(7 * 2.3) = round(16.1) = 16
  end)
end)
