local nivvie = {}

---@param cfg? nivvie.config.proto
function nivvie.setup(cfg)
  cfg = cfg or {}
  require('nivvie.config').set(cfg)
end

nivvie.autorestored = false
nivvie.stdin = false

function nivvie.get_uri()
  return string.gsub(vim.fn.getcwd(), '[^a-zA-Z0-9_.-]', function(s)
    return '<' .. vim.fn.char2nr(s)
  end)
end

---@param name? string
function nivvie.get_path(name)
  local sessiondir = require('nivvie.config').get().session_dir
  return vim.fs.joinpath(sessiondir, (name or nivvie.get_uri()) .. '.vim')
end

---@param name? string
function nivvie.save(name)
  local session_file = nivvie.get_path(name)

  local sessiondir = require('nivvie.config').get().session_dir
  vim.fn.mkdir(sessiondir, 'p')

  vim.api.nvim_cmd({
    cmd = 'mksession',
    bang = true,
    args = { session_file },
  }, {})
end

function nivvie.clean()
  vim.iter(ipairs(vim.api.nvim_list_bufs())):each(function(_, bufnr)
    if vim.bo[bufnr].buftype ~= '' then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end)
end

---@param name? string
function nivvie.restore(name)
  local path = nivvie.get_path(name)
  if vim.uv.fs_stat(path) then
    vim.api.nvim_cmd({
      cmd = 'source',
      args = { path },
    }, {})
    vim.api.nvim_exec_autocmds('SessionLoadPost', {})
  end
end

----

function nivvie.isemptysession()
  if nivvie.stdin then
    return false
  end

  if vim.fn.argc() > 0 then
    return false
  end

  local bufs = vim.api.nvim_list_bufs()
  bufs = vim
    .iter(bufs)
    :filter(function(buf)
      return vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buftype == ''
        and #vim.api.nvim_buf_get_name(buf) > 0
    end)
    :totable()

  return #bufs == 0
end

--- only restore if necessary
function nivvie.autorestore()
  if not require('nivvie.config').get().autorestore then
    return
  end

  if not nivvie.isemptysession() then
    return
  end

  nivvie.autorestored = true

  nivvie.restore()
end

-- only save if nvim was not started with file arguments/stdin
function nivvie.autosave()
  if not nivvie.autorestored then
    return
  end

  if not require('nivvie.config').get().autosave then
    return
  end

  require('nivvie').clean()
  require('nivvie').save()
end

return nivvie
