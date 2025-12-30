local MAX_SIZE_BYTES = 10 * 1024 * 1024 -- 10 MiB
local KEEP = 5

local uv = (vim.uv or vim.loop)

local function rotate_lsp_log()
  local log_path = vim.lsp.get_log_path()
  local stat = uv.fs_stat(log_path)
  if not (stat and stat.size and stat.size > MAX_SIZE_BYTES) then
    return
  end

  local dir = vim.fs.dirname(log_path)
  local base = vim.fs.basename(log_path)

  local function path_for(i)
    return string.format("%s/%s.%d.gz", dir, base, i)
  end

  -- delete oldest if exists
  local oldest = path_for(KEEP)
  if uv.fs_stat(oldest) then
    uv.fs_unlink(oldest)
  end

  -- shift logs N→N+1
  for i = KEEP - 1, 1, -1 do
    local src = path_for(i)
    local dst = path_for(i + 1)
    if uv.fs_stat(src) then
      uv.fs_rename(src, dst)
    end
  end

  -- rename current log to .1 (temporarily without gz)
  -- .1 should not exist due to rotation loop above
  local tmp_rotated = string.format("%s/%s.1", dir, base)
  uv.fs_rename(log_path, tmp_rotated)

  -- gzip it
  vim.system({ "gzip", "-f", tmp_rotated }, { detach = true }, function(res)
    if res.code ~= 0 then
      vim.notify("Failed to gzip rotated LSP log", vim.log.levels.WARN)
    end
  end)
end

-- Just being extra safe.  this SHOULDN'T get GC'd even if it were just a one-liner,
-- but adding the local variables will force it to stay around until the nvim
-- process exits.  Probably overly-paranoid here...
local uv = vim.uv or vim.loop
local log_timer = uv.new_timer()
-- Start without delay (at launch), and run once an hour thereafter.
log_timer:start(0, 1000 * 60 * 60, vim.schedule_wrap(rotate_lsp_log))
