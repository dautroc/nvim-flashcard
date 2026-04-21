local picker = require("flashcard.picker")

local function fake_adapter(available, record)
  return {
    is_available = function()
      return available
    end,
    pick = function(items, opts, on_choose)
      record.called = true
      record.items = items
      record.opts = opts
      record.on_choose = on_choose
    end,
  }
end

describe("picker dispatcher", function()
  it("calls cfg.picker directly when it is a function", function()
    local record = {}
    local fn = function(items, opts, on_choose)
      record.called = true
      record.items = items
      record.opts = opts
      record.on_choose = on_choose
    end
    picker.pick(
      { { name = "a", path = "/a.md" } },
      { prompt = "Study", cfg = { picker = fn } },
      function() end
    )
    assert.is_true(record.called)
    assert.equals("Study", record.opts.prompt)
  end)

  it("resolves a string name to the matching adapter", function()
    local record = {}
    picker._set_adapters({
      snacks = fake_adapter(true, record),
      select = fake_adapter(true, {}),
    })
    picker.pick(
      { { name = "a", path = "/a.md" } },
      { prompt = "Edit", cfg = { picker = "snacks" } },
      function() end
    )
    assert.is_true(record.called)
  end)

  it("falls back to select when a named adapter is unavailable", function()
    local snacks_rec, select_rec = {}, {}
    picker._set_adapters({
      snacks = fake_adapter(false, snacks_rec),
      select = fake_adapter(true, select_rec),
    })
    picker.pick(
      { { name = "a", path = "/a.md" } },
      { prompt = "Study", cfg = { picker = "snacks" } },
      function() end
    )
    assert.is_nil(snacks_rec.called)
    assert.is_true(select_rec.called)
  end)

  it("auto-detects in order snacks → telescope → select when cfg.picker is nil", function()
    local recs = { snacks = {}, telescope = {}, select = {} }
    picker._set_adapters({
      snacks = fake_adapter(false, recs.snacks),
      telescope = fake_adapter(true, recs.telescope),
      select = fake_adapter(true, recs.select),
    })
    picker.pick({ { name = "a", path = "/a.md" } }, { prompt = "Study", cfg = {} }, function() end)
    assert.is_nil(recs.snacks.called)
    assert.is_true(recs.telescope.called)
    assert.is_nil(recs.select.called)
  end)

  it("notifies and exits when items is empty", function()
    local notified = false
    local orig = vim.notify
    vim.notify = function(_, _)
      notified = true
    end
    picker._set_adapters({
      select = fake_adapter(true, {}),
    })
    picker.pick({}, { prompt = "Study", cfg = {} }, function() end)
    vim.notify = orig
    assert.is_true(notified)
  end)
end)
