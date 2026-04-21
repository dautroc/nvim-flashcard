local deck = require("flashcard.deck")
local util = require("flashcard.util")

local FIXTURES = vim.fn.getcwd() .. "/tests/fixtures"

describe("deck.parse — simple deck", function()
  local result

  before_each(function()
    result = deck.parse(FIXTURES .. "/simple.md")
  end)

  it("returns no error", function()
    assert.is_nil(result.err)
  end)

  it("parses two cards", function()
    assert.equals(2, #result.cards)
  end)

  it("trims front and back", function()
    assert.equals("What is the capital of France?", result.cards[1].front)
    assert.equals("Paris.", result.cards[1].back)
    assert.equals("What is 2+2?", result.cards[2].front)
    assert.equals("4", result.cards[2].back)
  end)

  it("assigns stable IDs based on front hash", function()
    assert.equals(util.hash("What is the capital of France?"), result.cards[1].id)
  end)
end)

describe("deck.parse — heading and intro", function()
  it("ignores content before the first card and parses cards", function()
    local result = deck.parse(FIXTURES .. "/heading-and-intro.md")
    assert.is_nil(result.err)
    assert.equals(2, #result.cards)
    assert.equals("What is the capital of France?", result.cards[1].front)
    assert.equals("What is the largest ocean?", result.cards[2].front)
  end)
end)

describe("deck.parse — malformed cards", function()
  it("skips invalid cards and returns valid ones with warnings", function()
    local result = deck.parse(FIXTURES .. "/malformed-mixed.md")
    assert.is_nil(result.err)
    assert.equals(1, #result.cards)
    assert.equals("Good question?", result.cards[1].front)
    assert.is_true(#result.warnings >= 2)
  end)
end)

describe("deck.parse — no cards", function()
  it("returns an error", function()
    local result = deck.parse(FIXTURES .. "/no-cards.md")
    assert.truthy(result.err)
    assert.same({}, result.cards or {})
  end)
end)

describe("deck.parse — missing file", function()
  it("returns an error", function()
    local result = deck.parse("/nonexistent/deck.md")
    assert.truthy(result.err)
  end)
end)
