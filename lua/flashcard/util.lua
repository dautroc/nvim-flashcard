local M = {}

function M.hash(text)
  return vim.fn.sha256(text):sub(1, 16)
end

function M.trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.today()
  return os.date("%Y-%m-%d")
end

function M.add_days(iso_date, days)
  local y, m, d = iso_date:match("^(%d+)-(%d+)-(%d+)$")
  assert(y, "invalid iso date: " .. tostring(iso_date))
  -- hour=12 avoids DST-related off-by-one across time-zone transitions
  local t = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
  return os.date("%Y-%m-%d", t + days * 86400)
end

return M
