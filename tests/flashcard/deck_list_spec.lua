local deck = require("flashcard.deck")

local function make_tmpdir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return dir
end

local function write_file(path, content)
  local f = assert(io.open(path, "w"))
  f:write(content)
  f:close()
end

describe("deck.list", function()
  it("returns empty list for missing dir", function()
    local result = deck.list("/nonexistent/path/xyz123")
    assert.same({}, result)
  end)

  it("returns empty list for empty dir", function()
    local dir = make_tmpdir()
    assert.same({}, deck.list(dir))
  end)

  it("lists only .md files", function()
    local dir = make_tmpdir()
    write_file(dir .. "/geography.md", "")
    write_file(dir .. "/history.md", "")
    write_file(dir .. "/readme.txt", "")
    write_file(dir .. "/geography.state.json", "")

    local result = deck.list(dir)
    table.sort(result, function(a, b)
      return a.name < b.name
    end)

    assert.equals(2, #result)
    assert.equals("geography", result[1].name)
    assert.equals(dir .. "/geography.md", result[1].path)
    assert.equals("history", result[2].name)
  end)

  it("ignores subdirectories", function()
    local dir = make_tmpdir()
    vim.fn.mkdir(dir .. "/nested", "p")
    write_file(dir .. "/nested/inner.md", "")
    write_file(dir .. "/outer.md", "")

    local result = deck.list(dir)
    assert.equals(1, #result)
    assert.equals("outer", result[1].name)
  end)
end)
