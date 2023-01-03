-- a lovr-ui window for editing physics world parameters
local ui = require'lib/ui'
local serpent = require'lib/serpent'
local phywire = require'lib/phywire'

local p = {} -- transient ui values


local function listScenes()
  local list = {}
  for _, filename in ipairs(lovr.filesystem.getDirectoryItems('')) do
    if filename:sub(#filename - 3, #filename) == '.phy' then
      table.insert(list, filename:sub(1, #filename - 4))
    end
  end
  return list
end


return function(pass, world, replaceWorld)
  ui.Begin('scenes', mat4(-0.7, 1.6, -0.7, math.pi/6, 0,1,0))
  ui.Label('░ SCENES', true)
  ui.Separator()
  p.scene_list = p.scene_list or listScenes()
  local modified, index = ui.ListBox('models', 5, 20, p.scene_list)
  if index then
    ui.SameLine()
    if ui.Button('⏏ load') then
      local filename = p.scene_list[index] .. '.phy'
      local snapshot_str = lovr.filesystem.read(filename)
      local ok, retval = serpent.load(snapshot_str)
      if ok then
        phywire.next_color_index = 1
        local new_world = phywire.fromSnapshot(retval)
        replaceWorld(new_world)
        p.status = string.format('> %s loaded', filename)
      else
        p.status = 'error: ' .. tostring(retval)
      end
    end
  end
  _, _, _, p.scene_name = ui.TextBox('name', 10, p.scene_name or '001')
  ui.SameLine()
  if ui.Button('✎ save') then
    local filename = p.scene_name .. '.phy'
    local snapshot = phywire.toSnapshot(world)
    lovr.filesystem.write(filename, serpent.block(snapshot))
    p.scene_list = listScenes()
    p.status = string.format('> %s saved', filename)
  end
  ui.Label(p.status or '')
  ui.End(pass)
end
