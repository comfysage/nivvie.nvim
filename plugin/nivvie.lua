if vim.g.loaded_session then
  return
end

vim.g.loaded_session = true

local group = vim.api.nvim_create_augroup('nivvie', { clear = true })

vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
  group = group,
  callback = function()
    if not require('nivvie.config').get().autosave then
      return
    end
    require('nivvie').clean()
    require('nivvie').save()
  end,
})

vim.api.nvim_create_autocmd({ 'StdinReadPost' }, {
  group = group,
  callback = function()
    require('nivvie').stdin = true
  end,
})

vim.schedule(function()
  vim.api.nvim_create_user_command('Nivvie', function(args)
    if args.fargs[1] == 'save' then
      require('nivvie').save(args.fargs[2])
      return
    elseif args.fargs[1] == 'restore' then
      require('nivvie').restore(args.fargs[2])
      return
    elseif args.fargs[1] == 'delete' then
      local path = require('nivvie').get_path(args.fargs[2])
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
    require('nivvie').autorestore()
  end)
  return
end

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  group = group,
  callback = function()
    vim.schedule(function()
      require('nivvie').autorestore()
    end)
  end,
})
