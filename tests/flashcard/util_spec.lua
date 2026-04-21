local util = require("flashcard.util")

describe("util.hash", function()
  it("returns a 16-char hex string", function()
    local h = util.hash("hello")
    assert.equals(16, #h)
    assert.truthy(h:match("^[0-9a-f]+$"))
  end)

  it("is deterministic", function()
    assert.equals(util.hash("hello"), util.hash("hello"))
  end)

  it("is different for different input", function()
    assert.are_not.equal(util.hash("hello"), util.hash("world"))
  end)
end)

describe("util.trim", function()
  it("strips leading and trailing whitespace", function()
    assert.equals("foo bar", util.trim("  foo bar\n\t "))
  end)

  it("leaves already-trimmed strings alone", function()
    assert.equals("foo", util.trim("foo"))
  end)
end)

describe("util.today", function()
  it("returns a string in YYYY-MM-DD format", function()
    local s = util.today()
    assert.truthy(s:match("^%d%d%d%d%-%d%d%-%d%d$"))
  end)
end)

describe("util.add_days", function()
  it("adds days across month boundary", function()
    assert.equals("2026-02-03", util.add_days("2026-01-30", 4))
  end)

  it("subtracts days with a negative delta", function()
    assert.equals("2026-01-30", util.add_days("2026-02-03", -4))
  end)

  it("returns same date for 0 delta", function()
    assert.equals("2026-04-21", util.add_days("2026-04-21", 0))
  end)
end)
