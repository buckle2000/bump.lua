local bump       = require 'bump'
local bump_debug = require 'bump_debug'

local instructions = [[
  bump.lua simple demo

    arrows: move
    tab: toggle debug info
    delete: run garbage collector
]]

local cols_len = 0 -- how many collisions are happening

-- World creation
local world = bump.newWorld()

-- in the shadow of at least one side of rect
local function on_side_of_rect(x,y,w,h,px,py)
  return (x<=px and px<=x+w) or (y<=py and py<=y+h)
end


local abs = math.abs

local function nearest(x, a, b)
  if abs(a - x) < abs(b - x) then return a else return b end
end

local function sign(x)
  if x > 0 then return 1 end
  if x == 0 then return 0 end
  return -1
end



-- local function bypass(world, col, x,y,w,h, goalX, goalY, filter)
--   local ri,ro = col.itemRect, col.otherRect
--   local midx, midy = col.touch.x + w/2, col.touch.y + h/2  -- center of item when touch
--   if in_side_of_rect(ro.x, ro.y, ro.w, ro.h, midx, midy) then
--     return bump.responses.slide(world, col, x,y,w,h, goalX, goalY, filter)
--   else
--     local nx, ny = bump.rect.getNearestCorner(ro.x, ro.y, ro.w, ro.h, midx, midy)  -- corner of col.other
--     local mid2x, mid2y = ri.x + w/2, ri.y + h/2  -- center of item which 'stuck' in other object
--     local nix, niy = bump.rect.getNearestCorner(ri.x, ri.y, ri.w, ri.h, nx, ny)  -- corner of col.item
--     local bx, by = ri.x, ri.y
--     local tunnel_x = col.normal.x == 0 and on_different_side(nx, midx, mid2x)
--     local tunnel_y = col.normal.y == 0 and on_different_side(ny, midy, mid2y)
--     -- if tunnel through col.other
--     -- likely will never happen
--     if tunnel_x or tunnel_y then
--       error()
--       -- align 
--       if tunnel_x then
--         bx = bx + nx - nix
--         goalX = bx
--       end
--       if tunnel_y then
--         by = by + ny - niy
--         goalY = by
--       end
--       -- goalX, goalY = bx + (goalX-x) * (1-col.ti), by + (goalY-y) * (1-col.ti)
--       local cols, len = world:project(col.item, bx, by, w, h, goalX, goalY, function () return 'bypass' end)
--       return goalX, goalY, cols, len
--     else
--       -- todo ellipse 插值
--       local size_el = ((mid2x-nix)/w*2)^2 + ((mid2y-niy)/h*2)^2  -- ellipse function: x^2/(w/2)^2 + y^2/(h/2)^2 = size_el
--       if size_el < 1 then
--         local dx, dy = (mid2x - nix) / size_el, (mid2y - niy) / size_el
--         goalX = goalX + dx
--         goalY = goalY + dy
--         bx, by = bx + dx, by + dy
--       end
--       local cols, len = world:project(col.item, bx, by, w, h, goalX, goalY, filter)
--       return goalX, goalY, cols, len
--     end
--   end
-- end

-- world:addResponse('bypass', bypass)

-- Message/debug functions
local function drawMessage()
  local msg = instructions:format(tostring(shouldDrawDebug))
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(msg, 550, 10)
end

local function drawDebug()
  bump_debug.draw(world)

  local statistics = ("fps: %d, mem: %dKB, collisions: %d, items: %d"):format(love.timer.getFPS(), collectgarbage("count"), cols_len, world:countItems())
  love.graphics.setColor(255, 255, 255)
  love.graphics.printf(statistics, 0, 580, 790, 'right')
end

local consoleBuffer = {}
local consoleBufferSize = 15
for i=1,consoleBufferSize do consoleBuffer[i] = "" end
local function consolePrint(msg)
  table.remove(consoleBuffer,1)
  consoleBuffer[consoleBufferSize] = msg
end

local function drawConsole()
  local str = table.concat(consoleBuffer, "\n")
  for i=1,consoleBufferSize do
    love.graphics.setColor(255,255,255, i*255/consoleBufferSize)
    love.graphics.printf(consoleBuffer[i], 10, 580-(consoleBufferSize - i)*12, 790, "left")
  end
end

-- helper function
local function drawBox(box, r,g,b)
  love.graphics.setColor(r,g,b,70)
  love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
  love.graphics.setColor(r,g,b)
  love.graphics.rectangle("line", box.x, box.y, box.w, box.h)
end



-- Player functions
local player = { x=400,y=450,w=20,h=20, speed = 80 }

local function updatePlayer(dt)
  local speed = player.speed

  local dx, dy = 0, 0
  if love.keyboard.isDown('right') then
    dx = speed * dt
  elseif love.keyboard.isDown('left') then
    dx = -speed * dt
  end
  if love.keyboard.isDown('down') then
    dy = speed * dt
  elseif love.keyboard.isDown('up') then
    dy = -speed * dt
  end

  if dx ~= 0 or dy ~= 0 then
    local cols
    player.x, player.y, cols, cols_len = world:move(player, player.x + dx, player.y + dy, function() return 'bypass' end)
    for i=1, cols_len do
      local col = cols[i]
      consolePrint(("col.other = %s, col.type = %s, col.normal = %d,%d"):format(col.other, col.type, col.normal.x, col.normal.y))
    end
  end
end

local function drawPlayer()
  drawBox(player, 0, 255, 0)
end

-- Block functions

local blocks = {}

local function addBlock(x,y,w,h)
  local block = {x=x,y=y,w=w,h=h}
  blocks[#blocks+1] = block
  world:add(block, x,y,w,h)
end

local function drawBlocks()
  for _,block in ipairs(blocks) do
    drawBox(block, 255,0,0)
  end
end




-- Main LÖVE functions

function love.load()
  world:add(player, player.x, player.y, player.w, player.h)

  addBlock(0,       0,     800, 32)
  addBlock(0,      32,      32, 600-32*2)
  addBlock(800-32, 32,      32, 600-32*2)
  addBlock(0,      600-32, 800, 32)

  for i=1,30 do
    addBlock( math.random(100, 600),
              math.random(100, 400),
              math.random(10, 100),
              math.random(10, 100)
    )
  end
end

function love.update(dt)
  cols_len = 0
  updatePlayer(dt)
end

function love.draw()
  drawBlocks()
  drawPlayer()
  if shouldDrawDebug then
    drawDebug()
    drawConsole()
  end
  drawMessage()
end

-- Non-player keypresses
function love.keypressed(k)
  if k=="escape" then love.event.quit() end
  if k=="tab"    then shouldDrawDebug = not shouldDrawDebug end
  if k=="delete" then collectgarbage("collect") end
  if k=="f"      then player.speed = 10000 - player.speed end
end
