local m = {}

m._selection = nil


function m.get()
  return m._selection
end


function m.set(collider)
  m._selection = collider
end


function m.update(dt, world)
  for i, hand in ipairs(lovr.headset.getHands()) do
    -- laser selection of colliders
    if lovr.headset.wasPressed(hand, 'x') or lovr.headset.wasPressed(hand, 'a') then
      m.laserSelect(world, hand)
    end
    -- positioning and rotating the selected collider
    if lovr.headset.isDown(hand, 'grip') and m._selection then
      local pos = vec3(m._selection:getPosition())
      pos:add(vec3(lovr.headset.getVelocity(hand)):mul(dt))
      m._selection:setPosition(pos)
      local ax, ay = lovr.headset.getAxis(hand, 'thumbstick')
      if math.abs(ax) > 0.1 or math.abs(ay) > 0.1 then
        local orientation = quat(m._selection:getOrientation())
        orientation:mul(quat(ax * dt, 0, 1, 0)):mul(quat(ay * dt, 1, 0, 0))
        m._selection:setOrientation(orientation)
      end
      m._selection:setLinearVelocity(0,0,0)
      m._selection:setAngularVelocity(0,0,0)
    end
  end
end


function m.laserSelect(world, hand)
  hand = hand or 'left'
  local ray_orientation = quat(lovr.headset.getOrientation(hand))
  local ray_origin = vec3(lovr.headset.getPosition(hand))
  ray_orientation:mul(quat(-math.pi / 3, 1,0,0)) -- same rotation is done in UI lib
  ray_origin:add(ray_orientation:direction():mul(0.05))
  local ray_destination = vec3(ray_origin):add(ray_orientation:mul(vec3(0, 0, -20)))
  local closest = math.huge
  local selected
  world:raycast(ray_origin, ray_destination,
    function(shape, x, y, z)
      local distance = vec3(x, y, z):distance(vec3(ox, oy, oz))
      if distance < closest then
        selected = shape:getCollider()
        closest = distance
      end
    end)
  m.set(selected)
end

return m
