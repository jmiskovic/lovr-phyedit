-- a lovr-ui window with options for lovr-phywire library
local ui = require'lib/ui'

local p = {}

return function(pass, phywire_options)
  ui.Begin('phywire', mat4(-0.7, 0.8, -0.7, math.pi/6, 0,1,0))
  ui.Label('░ VISUALIZATION SETTINGS', true)
  ui.Separator()
  if ui.CheckBox('wireframe', phywire_options.wireframe) then
    phywire_options.wireframe = not phywire_options.wireframe
    phywire_options.show_shapes = phywire_options.wireframe
  end
  ui.SameLine()
  if ui.CheckBox('overdraw', phywire_options.overdraw) then
    phywire_options.overdraw = not phywire_options.overdraw
  end
  if ui.CheckBox('velocities', phywire_options.show_velocities) then
    phywire_options.show_velocities = not phywire_options.show_velocities
  end
  ui.SameLine()
  if ui.CheckBox('angulars', phywire_options.show_angulars) then
    phywire_options.show_angulars = not phywire_options.show_angulars
  end
  if ui.CheckBox('joints', phywire_options.show_joints) then
    phywire_options.show_joints = not phywire_options.show_joints
  end
  ui.SameLine()
  if ui.CheckBox('contacts', phywire_options.show_contacts) then
    phywire_options.show_contacts = not phywire_options.show_contacts
  end
  _, phywire_options.geometry_segments = ui.SliderInt('segments', phywire_options.geometry_segments, 3, 40)
  ui.Separator()
  local modified
  modified, p.framerate = ui.SliderInt('physics framerate', p.framerate or phywire_options.framerate, 1, 200)
  if modified then phywire_options.framerate = p.framerate end
  local running_label = phywire_options.framerate > 0 and 'ǁ pause' or '‣ run'
  if ui.Button(running_label) then
    phywire_options.framerate = phywire_options.framerate > 0 and 0 or p.framerate
  end
  ui.End(pass)
end
