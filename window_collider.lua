-- a lovr-ui window for modifying collider parameters & for editing joints
local phywire = require'lib/phywire'
local ui = require'lib/ui'
local collider_selection = require'collider_selection'

local p = {}  -- transient ui values
p.collider = nil            -- currently edited collider
p.newjoint = nil            -- type of joint to be created

local function selectJoint(joint)
  local type = joint:getType()
  if type == 'ball' or type == 'distance' then
    p.joint_tightness = joint:getTightness()
    local response_time = joint:getResponseTime()
    p.joint_response_exp = math.floor(math.log10(response_time * 1.001))
    p.joint_response_frac = response_time * 10^ -p.joint_response_exp
  elseif type == 'hinge' or type == 'slider' then
    p.joint_lowerlimit = joint:getLowerLimit()
    p.joint_upperlimit = joint:getUpperLimit()
  end
end


local function updateJointList(collider)
  p.jointlist = {}
  for i, joint in ipairs(collider:getJoints()) do
    table.insert(p.jointlist, joint:getType())
  end
  if #p.jointlist > 0 then
    selectJoint(collider:getJoints()[1])
  end
end


local function createJoint(a, b, type)
  if a == b then return false end
  if type == 'ball' then
    lovr.physics.newBallJoint(a, b, a:getPosition())
    return true
  elseif type == 'distance' then
    local xa, ya, za = a:getPosition()
    local xb, yb, zb = b:getPosition()
    lovr.physics.newDistanceJoint(a, b, xa, ya, za, xb, yb, zb)
    return true
  elseif type == 'hinge' then
    local xa, ya, za = a:getPosition()
    local xb, yb, zb = b:getPosition()
    local ax, ay, ab = vec3(xa, ya, za):sub(xb, yb, zb):normalize():unpack()
    lovr.physics.newHingeJoint(a, b, xa, ya, za, ax, ay, ab)
    return true
  elseif type == 'slider' then
    local xa, ya, za = a:getPosition()
    local xb, yb, zb = b:getPosition()
    local ax, ay, ab = vec3(xa, ya, za):sub(xb, yb, zb):normalize():unpack()
    lovr.physics.newSliderJoint(a, b, ax, ay, ab)
    return true
  end
  return false
end


function selectCollider(collider)
  if p.newjoint and collider then
    createJoint(p.collider, collider, p.newjoint)
  end
  p.newjoint = nil
  p.collider = collider
  if not collider then return end
  p.mass = collider:getMass()
  p.friction = collider:getFriction()
  p.restitution = collider:getRestitution()
  p.lineardamping = collider:getLinearDamping()
  p.angulardamping = collider:getAngularDamping()
  p.shapes = {}
  local max_dimension = 0
  for _, shape in ipairs(collider:getShapes()) do
    local s = {}
    s.orientation = {shape:getOrientation()}
    s.position = {shape:getPosition()}
    s.enabled = shape:isEnabled()
    s.sensor = shape:isSensor()
    s.type = shape:getType()
    if s.type == 'box' then
      s.dimensions = {shape:getDimensions()}
      max_dimension = math.max(max_dimension, s.dimensions[1])
      max_dimension = math.max(max_dimension, s.dimensions[2])
      max_dimension = math.max(max_dimension, s.dimensions[3])
    elseif s.type == 'sphere' then
      s.radius = shape:getRadius()
      max_dimension = math.max(max_dimension, s.radius)
    elseif s.type == 'capsule' or s.type == 'cylinder' then
      s.radius = shape:getRadius()
      s.length = shape:getLength()
      max_dimension = math.max(max_dimension, s.radius)
      max_dimension = math.max(max_dimension, s.length)
    end
    table.insert(p.shapes, s)
  end
  p.max_dimension_exp = math.floor(math.log10(max_dimension * 1.001)) + 1
  updateJointList(collider)
end

local joint_types = {'ball', 'distance', 'hinge', 'slider'}
local joint_to_icon = {ball = 'Ͽ ', distance = '↔ ', hinge = '⚕ ', slider = '⇌ '}
local shape_to_icon = {box = '□ ', sphere = '○ ', cylinder = 'ອ ', capsule = 'Ο '}


return function (pass)
  local selected = collider_selection.get()
  if p.collider ~= selected then
    selectCollider(selected)
  end
  ui.Begin('collider-properties', mat4(0.7, 1.2, -0.7, -math.pi/6, 0,1,0))
  ui.Label('░ COLLIDER SETTINGS')
  ui.Separator()
  if not selected then
    ui.Label('⬚ select a collider with X or A button', true)
  else
    local collider = selected
    if ui.CheckBox('kinematic', collider:isKinematic()) then collider:setKinematic(not collider:isKinematic()) end
    ui.SameLine() ui.Dummy(40, 0) ui.SameLine()
    if ui.CheckBox('gravity ignored', collider:isGravityIgnored()) then collider:setGravityIgnored(not collider:isGravityIgnored()) end
    if ui.CheckBox('sleeping allowed', collider:isSleepingAllowed()) then collider:setSleepingAllowed(not collider:isSleepingAllowed()) end
    ui.SameLine() ui.Dummy(40, 0) ui.SameLine()
    if ui.CheckBox('awake', collider:isAwake()) then collider:setAwake(not collider:isAwake()) end

    local modified
    modified, p.mass = ui.SliderFloat('mass', p.mass, 0.001, 10, 800)
    if modified then
      collider:setMass(p.mass)
      p.mass = collider:getMass()
    end
    modified, p.friction = ui.SliderFloat('friction', p.friction, 0, 5, 800)
    if modified then
      collider:setFriction(p.friction)
      p.friction = collider:getFriction()
    end
    modified, p.restitution = ui.SliderFloat('restitution', p.restitution, 0, 5, 800)
    if modified then
      collider:setRestitution(p.restitution)
      p.restitution = collider:getRestitution()
    end
    modified, p.lineardamping = ui.SliderFloat('linear damping', p.lineardamping, 0, 0.5, 800)
    if modified then
      collider:setLinearDamping(p.lineardamping)
      p.lineardamping = collider:getLinearDamping()
    end
    modified, p.angulardamping = ui.SliderFloat('angular damping', p.angulardamping, 0, 0.15, 800)
    if modified then
      collider:setAngularDamping(p.angulardamping)
      p.angulardamping = collider:getAngularDamping()
    end
    local shapes = collider:getShapes()
    for i, shape in ipairs(p.shapes) do
      ui.Separator()
      ui.Label(shape_to_icon[shape.type] .. shape.type .. ' shape')
      ui.SameLine() ui.Dummy(40, 0) ui.SameLine()
      if ui.CheckBox('sensor', shape.sensor) then
        shape.sensor = not shape.sensor
        shapes[i]:setSensor(shape.sensor)
      end
      ui.SameLine() ui.Dummy(40, 0) ui.SameLine()
      if ui.CheckBox('enabled', shape.enabled) then
        shape.enabled = not shape.enabled
        shapes[i]:setEnabled(shape.enabled)
      end
      ui.Label('⇲ dimensions')
      local min_dimension = 0.0001
      local max_dimension = 10^p.max_dimension_exp
      if shape.type == 'box' then
        local modified_w, modified_h, modified_d
        modified_w, shape.dimensions[1] = ui.SliderFloat('w', shape.dimensions[1], min_dimension, max_dimension, 1000, 3)
        modified_h, shape.dimensions[2] = ui.SliderFloat('h', shape.dimensions[2], min_dimension, max_dimension, 1000, 3)
        modified_d, shape.dimensions[3] = ui.SliderFloat('d', shape.dimensions[3], min_dimension, max_dimension, 1000, 3)
        if modified_w or modified_h or modified_d then shapes[i]:setDimensions(unpack(shape.dimensions)) end
      elseif shape.type == 'sphere' then
        local modified_r
        modified_r, shape.radius = ui.SliderFloat('r', shape.radius, min_dimension, max_dimension, 1000, 3)
        if modified_r then shapes[i]:setRadius(shape.radius) end
      elseif shape.type == 'capsule' or shape.type == 'cylinder' then
        local modified_r, modified_l
        modified_r, shape.radius = ui.SliderFloat('r', shape.radius, min_dimension, max_dimension, 1000, 3)
        if modified_r then shapes[i]:setRadius(shape.radius) end
        modified_l, shape.length = ui.SliderFloat('l', shape.length, min_dimension, max_dimension, 1000, 3)
        if modified_l then shapes[i]:setLength(shape.length) end
      end
      ui.Label('⍚ shape position & orientation')
      local modified_a, modified_x, modified_y, modified_z
      modified_x, shape.position[1] = ui.SliderFloat('x', shape.position[1], -max_dimension, max_dimension)
      ui.SameLine()
      modified_y, shape.position[2] = ui.SliderFloat('y', shape.position[2], -max_dimension, max_dimension)
      ui.SameLine()
      modified_z, shape.position[3] = ui.SliderFloat('z', shape.position[3], -max_dimension, max_dimension)
      if modified_x or modified_y or modified_z then shapes[i]:setPosition(unpack(shape.position)) end
      modified_a, shape.orientation[1] = ui.SliderFloat('↺ angle', shape.orientation[1], -math.pi, math.pi, 1000, 3)
      modified_x, shape.orientation[2] = ui.SliderFloat('ax', shape.orientation[2], -1, 1)
      ui.SameLine()
      modified_y, shape.orientation[3] = ui.SliderFloat('ay', shape.orientation[3], -1, 1)
      ui.SameLine()
      modified_z, shape.orientation[4] = ui.SliderFloat('az', shape.orientation[4], -1, 1)
      if modified_a or modified_x or modified_y or modified_z then shapes[i]:setOrientation(unpack(shape.orientation)) end
      ui.Dummy(450, 0) ui.SameLine()
      if ui.Button('✘ destroy shape') then
        collider:removeShape(shapes[i])
        selectCollider(collider)
        break
      end
    end
    ui.Dummy(0, 20)
    ui.Label('✦ add shape:')
    ui.SameLine()
    if ui.Button('□ box') then
      collider:addShape(lovr.physics.newBoxShape(default_dim, default_dim, default_dim))
      selectCollider(selected)
    end
    ui.SameLine()
    if ui.Button('○ sphere') then
      collider:addShape(lovr.physics.newSphereShape(default_dim))
      selectCollider(selected)
    end
    ui.SameLine()
    if ui.Button('ອ cylinder') then
      collider:addShape(lovr.physics.newCylinderShape(default_dim, default_dim))
      selectCollider(selected)
    end
    ui.SameLine()
    if ui.Button('Ο capsule') then
      collider:addShape(lovr.physics.newCapsuleShape(default_dim, default_dim))
      selectCollider(selected)
    end
    ui.Separator()
    ui.Dummy(0, 20)
    ui.Label('create joint:')
    ui.SameLine()
    for i, joint_type in ipairs(joint_types) do
      if i > 1 then ui.SameLine() end
      if ui.Button(joint_to_icon[joint_type] .. joint_type) then
        if p.newjoint == joint_type then
          p.newjoint = nil
        else
          p.newjoint = joint_type
        end
      end
    end
    if p.newjoint then
      ui.Label('...select other collider', true)
    end
    local modified, index = ui.ListBox('joints', 5, 10, p.jointlist)
    if modified then
      selectJoint(collider:getJoints()[index])
    end
    if index > 0 then
      local joint = collider:getJoints()[index]
      ui.SameLine()
      if ui.Button('remove joint') then
        joint:destroy()
        updateJointList()
      end
      local type = joint:getType()
      local modified
      if type == 'ball' or type == 'distance' then
        modified, p.joint_tightness = ui.SliderFloat('tightness', p.joint_tightness, 0, 1, 800)
        if modified then joint:setTightness(p.joint_tightness) end
        local modified_frac, modified_exp
        modified_frac, p.joint_response_frac = ui.SliderFloat('x 10^', p.joint_response_frac, 1, 10)
        ui.SameLine()
        modified_exp, p.joint_response_exp = ui.SliderInt('response time', p.joint_response_exp, -6, 4)
        if modified_frac or modified_exp then
          joint:setResponseTime(p.joint_response_frac * 10^p.joint_response_exp)
        end
      elseif type == 'hinge' then
        modified, p.joint_lowerlimit = ui.SliderFloat('lower limit', p.joint_lowerlimit, -math.pi, math.pi, 800)
        if modified then joint:setLowerLimit(p.joint_lowerlimit) end
        modified, p.joint_upperlimit = ui.SliderFloat('upper limit', p.joint_upperlimit, -math.pi, math.pi, 800)
        if modified then joint:setUpperLimit(p.joint_upperlimit) end
      elseif type == 'slider' then
        modified, p.joint_lowerlimit = ui.SliderFloat('lower limit', p.joint_lowerlimit, -5, 5, 800)
        if modified then joint:setLowerLimit(p.joint_lowerlimit) end
        modified, p.joint_upperlimit = ui.SliderFloat('upper limit', p.joint_upperlimit, -5, 5, 800)
        if modified then joint:setUpperLimit(p.joint_upperlimit) end
      end
    end
    ui.Dummy(450, 0) ui.SameLine()
    if ui.Button('✘ destroy collider') then
      collider:destroy()
      selectCollider(nil)
      collider_selection.set()
    end
  end
  ui.End(pass)
end
