local nivvie = {}

---@param cfg? nivvie.config
function nivvie.setup(cfg)
  cfg = cfg or {}
  require('nivvie.config').set(cfg)
end

return nivvie
