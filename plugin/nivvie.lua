if vim.g.loaded_session then
  return
end

vim.g.loaded_session = true

local logger = vim.log.new({
  name = "nivvie",
  level = vim.log.levels.DEBUG,
})

---@class nivvie.config
---@field session_dir string
---@field autosave boolean
---@field autorestore boolean
vim.g.nivvie = vim.tbl_extend("force", {
  -- where sessions are stored
  session_dir = vim.fn.stdpath("state") .. "/sessions",
  -- save on exit
  autosave = true,
  -- load on start
  autorestore = true,
}, vim.g.nivvie or {})

local nivvie = {}

nivvie.autorestored = false
nivvie.stdin = false

function nivvie.get_uri()
  return string.gsub(vim.fn.getcwd(), "[^a-zA-Z0-9_.-]", function(s)
    return "<" .. vim.fn.char2nr(s)
  end)
end

---@param name? string
function nivvie.get_path(name)
  local sessiondir = vim.g.nivvie.session_dir
  return vim.fs.joinpath(sessiondir, (name or nivvie.get_uri()) .. ".vim")
end

---@param name? string
function nivvie.save(name)
  local session_file = nivvie.get_path(name)

  local sessiondir = vim.g.nivvie.session_dir
  vim.fn.mkdir(sessiondir, "p")

  vim.api.nvim_cmd({
    cmd = "mksession",
    bang = true,
    args = { session_file },
  }, {})
end

function nivvie.clean()
  vim.iter(ipairs(vim.api.nvim_list_bufs())):each(function(_, bufnr)
    if vim.bo[bufnr].buftype ~= "" then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end)
end

---@param name? string
function nivvie.restore(name)
  local path = nivvie.get_path(name)
  if vim.uv.fs_stat(path) then
    vim.api.nvim_cmd({
      cmd = "source",
      args = { path },
    }, {})
    vim.v.this_session = path
    vim.api.nvim_exec_autocmds("SessionLoadPost", {})
  end
end

-------------------------------------------------------------------------------

function nivvie.isemptysession()
  -- whether StdinReadPost was handled or ttyin was set
  if nivvie.stdin or vim.fn.has("ttyin") == 0 then
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
        and vim.bo[buf].buftype == ""
        and #vim.api.nvim_buf_get_name(buf) > 0
    end)
    :totable()

  return #bufs == 0
end

--- only restore if necessary
function nivvie.autorestore()
  if not vim.g.nivvie.autorestore or nivvie.autorestored then
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

  if not vim.g.nivvie.autosave then
    return
  end

  nivvie.clean()
  nivvie.save()
end

-------------------------------------------------------------------------------

local group = vim.api.nvim_create_augroup("nivvie", { clear = true })

vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
  group = group,
  callback = function()
    nivvie.autosave()
  end,
})

vim.api.nvim_create_autocmd({ "StdinReadPost" }, {
  group = group,
  callback = function()
    nivvie.stdin = true
  end,
})

vim.schedule(function()
  vim.api.nvim_create_user_command("Nivvie", function(args)
    if args.fargs[1] == "save" then
      nivvie.save(args.fargs[2])
      return
    elseif args.fargs[1] == "restore" then
      nivvie.restore(args.fargs[2])
      return
    elseif args.fargs[1] == "delete" then
      local path = nivvie.get_path(args.fargs[2])
      if vim.uv.fs_stat(path) then
        vim.uv.fs_unlink(path)
      end
    end
  end, {
    nargs = "+",
    complete = function()
      return {
        "save",
        "restore",
        "delete",
      }
    end,
  })
end)

-------------------------------------------------------------------------------

if vim.v.vim_did_enter > 0 then
  vim.schedule(function()
    nivvie.autorestore()
  end)
  return
end

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = group,
  callback = function()
    vim.schedule(function()
      nivvie.autorestore()
    end)
  end,
})
