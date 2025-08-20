if vim.g.loaded_session then
  return
end

vim.g.loaded_session = true

local session = {}

---@private
session.stdin = false

function session.get_uri()
  return string.gsub(vim.fn.getcwd(), '[^a-zA-Z0-9_.-]', function(s)
    return '<' .. vim.fn.char2nr(s)
  end)
end

---@param name? string
function session.get_path(name)
  local sessiondir = require('nivvie.config').get().session_dir
  return vim.fs.joinpath(sessiondir, (name or session.get_uri()) .. '.vim')
end

---@param name? string
function session.save(name)
  local session_file = session.get_path(name)

  local sessiondir = require('nivvie.config').get().session_dir
  vim.fn.mkdir(sessiondir, 'p')

  vim.api.nvim_cmd({
    cmd = 'mksession',
    bang = true,
    args = { session_file },
  }, {})
end

function session.clean()
  vim.iter(ipairs(vim.api.nvim_list_bufs())):each(function(_, bufnr)
    if vim.bo[bufnr].buftype ~= '' then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end)
end

---@param name? string
function session.restore(name)
  local path = session.get_path(name)
  if vim.uv.fs_stat(path) then
    vim.api.nvim_cmd({
      cmd = 'source',
      args = { path },
    }, {})
    vim.api.nvim_exec_autocmds('SessionLoadPost', {})
  end
end

----

function session.isemptysession()
  if session.stdin then
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
function session.autorestore()
  if not require('nivvie.config').get().autorestore then
    return
  end

  if not session.isemptysession() then
    return
  end

  session.restore()
end

local group = vim.api.nvim_create_augroup('nivvie', { clear = true })

vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
  group = group,
  callback = function()
    if not require('nivvie.config').get().autosave then
      return
    end
    session.clean()
    session.save()
  end,
})

vim.api.nvim_create_autocmd({ 'StdinReadPost' }, {
  group = group,
  callback = function()
    session.stdin = true
  end,
})

vim.schedule(function()
  vim.api.nvim_create_user_command('Nivvie', function(args)
    if args.fargs[1] == 'save' then
      session.save(args.fargs[2])
      return
    elseif args.fargs[1] == 'restore' then
      session.restore(args.fargs[2])
      return
    elseif args.fargs[1] == 'delete' then
      local path = session.get_path(args.fargs[2])
      if vim.uv.fs_stat(path) then
        vim.uv.fs_unlink(path)
      end
    end
  end, {
    nargs = '+',
    complete = function()
      return {
        'save',
        'restore',
        'delete',
      }
    end,
  })
end)

----

if vim.v.vim_did_enter > 0 then
  vim.schedule(function()
    session.autorestore()
  end)
  return
end

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  group = group,
  callback = function()
    vim.schedule(function()
      session.autorestore()
    end)
  end,
})
