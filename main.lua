local phywire = require'lib/phywire'
local ui = require'lib/ui'
local ui_theme = require'ui_theme'
local collider_selection = require'collider_selection'

local window_scenes = require'window_scenes'
local window_collider = require'window_collider'
local window_phywire = require'window_phywire'
local window_world = require'window_world'

local shader = lovr.graphics.newShader('unlit', 'diffuse.frag')

local world
 
local function replaceWorld(new_world)
  world = new_world
  collider_selection.set()
end


function lovr.load()
  replaceWorld(lovr.physics.newWorld())
  local floor = world:newBoxCollider(0, -0.3, 0, 50, 0.6, 50)
  floor:setKinematic(true)
  ui.Init('hand/left')
  ui.SetColorTheme(ui_theme)
end

function lovr.update(dt)
  ui.InputInfo()
  collider_selection.update(dt, world)
  phywire.update(world)
end


function lovr.draw(pass)
  pass:setShader(shader)                          -- render world scene
  phywire.draw(pass, world, phywire.render_shapes)
  pass:setShader()

  local selection = collider_selection.get()      -- draw active selection
  if selection then
    pass:push('state')
    pass:setWireframe(true)
    pass:setDepthTest()
    phywire.drawCollider(pass, selection, phywire.render_wireframe)
    pass:pop('state')
  end

  ui.NewFrame(pass)                               -- process ui windows
  window_phywire(pass, phywire.options)
  window_world(pass, world)
  window_collider(pass)
  window_scenes(pass, world, replaceWorld)
  local passes = ui.RenderFrame(pass)

  phywire.draw(pass, world, phywire.options)

  table.insert(passes, pass)
  return lovr.graphics.submit(passes)
end


function lovr.keypressed(key, scancode, isrepeat)
  if key == 'tab' then
    collider_selection.laserSelect(world)
  end
end
