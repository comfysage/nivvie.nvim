local config = {}

---@class nivvie.config.proto
---@field session_dir? string
---@field autosave? boolean
---@field autorestore? boolean

---@class nivvie.config
---@field session_dir string
---@field autosave boolean
---@field autorestore boolean

---@type nivvie.config
config.default = {
  -- where sessions are stored
  session_dir = vim.fn.stdpath 'state' .. '/sessions',
  -- save on exit
  autosave = true,
  -- load on start
  autorestore = true,
}

---@type nivvie.config.proto
config.current = {}

---@return nivvie.config
function config.get()
  return vim.tbl_deep_extend('force', config.default, config.current)
end

---@param cfg nivvie.config.proto
---@return nivvie.config
function config.override(cfg)
  return vim.tbl_deep_extend('force', config.default, cfg)
end

---@param cfg nivvie.config.proto
function config.set(cfg)
  config.current = cfg
end

return config
