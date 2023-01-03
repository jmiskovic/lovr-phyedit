-- a lovr-ui window for editing physics world parameters
local ui = require'lib/ui'
local collider_selection = require'collider_selection'

local initial_size = 0.05   -- size of created colliders
local p = {} -- transient ui values

--- Calculates exponential part of response time (for 1.23e-4 returns -5)
local function getResponseTimeExp(world)
  local response_time = world:getResponseTime()
  return math.floor(math.log10(response_time * 1.001))
end

--- Calculates fractional part of response time (for 1.23e-4 returns 1.23)
local function getResponseTimeFrac(world)
  local exp = getResponseTimeExp(world)
  return world:getResponseTime() * 10^ -exp
end


return function(pass, world)
  ui.Begin('world', mat4(-0.7, 1.2, -0.7, math.pi/6, 0,1,0))
  ui.Label('░ WORLD SETTINGS', true)
  ui.Separator()
  local modified

  modified, p.world_stepcount = ui.SliderInt('step count', p.world_stepcount or world:getStepCount(), 1, 200, 1000)
  if modified then world:setStepCount(p.world_stepcount) end

  modified, p.world_tightness = ui.SliderFloat('tightness', p.world_tightness or world:getTightness(), 0, 1, 1000)
  if modified then world:setTightness(p.world_tightness) end

  local modified_frac, modified_exp
  modified_frac, p.world_response_frac = ui.SliderFloat('x 10^', p.world_response_frac or getResponseTimeFrac(world), 1, 10)
  ui.SameLine()
  modified_exp, p.world_response_exp = ui.SliderInt('response time', p.world_response_exp  or getResponseTimeExp(world), -6, 2)
  if modified_frac or modified_exp then
    world:setResponseTime(p.world_response_frac * 10^p.world_response_exp)
  end

  modified, p.world_lineardamping = ui.SliderFloat('linear damping', p.world_lineardamping or world:getLinearDamping(), 0, 0.15, 1000)
  if modified then
    world:setLinearDamping(p.world_lineardamping)
    p.world_lineardamping = world:getLinearDamping()
  end
  modified, p.world_angulardamping = ui.SliderFloat('angular damping', p.world_angulardamping or world:getAngularDamping(), 0, 0.15, 1000)
  if modified then
    world:setAngularDamping(p.world_angulardamping)
    p.world_angulardamping = world:getAngularDamping()
  end

  ui.Label('⇣ gravity', true)
  local modified_x, modified_y, modified_z
  modified_x, p.world_gx = ui.SliderFloat('x', p.world_gx or select(1, world:getGravity()), -10, 10)
  ui.SameLine()
  modified_y, p.world_gy = ui.SliderFloat('y', p.world_gy or select(2, world:getGravity()), -10, 10, 350)
  ui.SameLine()
  modified_z, p.world_gz = ui.SliderFloat('z', p.world_gz or select(3, world:getGravity()), -10, 10)

  if modified_x or modified_y or modified_z then world:setGravity(p.world_gx, p.world_gy, p.world_gz) end
  p.world_sleeping_allowed = p.world_sleeping_allowed or world:isSleepingAllowed()
  if ui.CheckBox('sleeping allowed', p.world_sleeping_allowed) then
    p.world_sleeping_allowed = not p.world_sleeping_allowed
    world:setSleepingAllowed(p.world_sleeping_allowed)
  end
  ui.Dummy(0, 20)

  ui.Label('✦ create collider:')
  ui.SameLine()
  if ui.Button('□ box') then
    local head_pose = mat4(lovr.headset.getPose())
    local x, y, z = head_pose:mul(0, -0.3, -0.5)
    local collider = world:newBoxCollider(x, y, z, initial_size, initial_size, initial_size)
    collider:setGravityIgnored(true)
    collider_selection.set(collider)
  end
  ui.SameLine()
  if ui.Button('○ sphere') then
    local head_pose = mat4(lovr.headset.getPose())
    local x, y, z = head_pose:mul(0, -0.3, -0.5)
    local collider = world:newSphereCollider(x, y, z, initial_size)
    collider:setGravityIgnored(true)
    collider_selection.set(collider)
  end
  ui.SameLine()
  if ui.Button('ອ cylinder') then
    local head_pose = mat4(lovr.headset.getPose())
    local x, y, z = head_pose:mul(0, -0.3, -0.5)
    local collider = world:newCylinderCollider(x, y, z, initial_size, initial_size)
    collider:setGravityIgnored(true)
    collider_selection.set(collider)
  end
  ui.SameLine()
  if ui.Button('Ο capsule') then
    local head_pose = mat4(lovr.headset.getPose())
    local x, y, z = head_pose:mul(0, -0.3, -0.5)
    local collider = world:newCapsuleCollider(x, y, z, initial_size, initial_size)
    collider:setGravityIgnored(true)
    collider_selection.set(collider)
  end
  ui.End(pass)
end
