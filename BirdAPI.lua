local currentver = 2.15

if BirdAPI then
  if BirdAPI.ver >= currentver then
    return
  end
end

BirdAPI = {}
BirdAPI.ver = currentver

local MultiUpdate = {}

function BirdAPI.moverbias(amount)
  return function(cell, dir, x, y, vars, side, force, ptype)
    if ptype == "push" then
      if side == 0 and not cell.frozen then cell.updated = cell.updated or not vars.noupdate return force - amount end
      if side == 2 and not cell.frozen then cell.updated = cell.updated or not vars.noupdate return force + amount end
    end
    return force
  end
end

function BirdAPI.DoGenerator(x,y,rot,dir,preaddedrot,offx,offy)
  dir = dir or rot
  preaddedrot = preaddedrot or 0
  offx = offx or 0
  offy = offy or 0
  local cx,cy,cdir = NextCell(x,y,(rot+2)%4,getempty())
  local fx,fy = GetFrontPos(x,y,dir,1)
  local gencell = CopyCell(cx,cy)
  NextCell(cx,cy,(cdir+2)%4,gencell,nil,nil,true)	--converts gencell
  gencell = ToGenerate(gencell,dir,x,y)
  if gencell then
    local gcellcop = table.copy(gencell)
    gcellcop.rot = (gcellcop.rot + preaddedrot + ((dir+2)%4 - cdir)) % 4
    gcellcop.lastvars = {x,y,gcellcop.rot}
    PushCell(fx+offx,fy+offy,dir,{replacecell = gcellcop,force = 1})
  end
end

function BirdAPI.GenerateCell(x,y,rot,dir,cell,preaddedrot,offx,offy)
  dir = dir or rot
  preaddedrot = preaddedrot or 0
  offx = offx or 0
  offy = offy or 0
  local cx,cy,cdir = NextCell(x,y,(rot+2)%4,getempty())
  local fx,fy = GetFrontPos(x,y,dir,1)
  cell = ToGenerate(cell,dir,x,y)
  if cell then
    local gcellcop = table.copy(cell)
    gcellcop.rot = (gcellcop.rot + preaddedrot + ((dir+2)%4 - cdir)) % 4
    gcellcop.lastvars = {x,y,gcellcop.rot}
    PushCell(fx+offx,fy+offy,dir,{replacecell = gcellcop,force = 1})
  end
end

function BirdAPI.randomcellid()
  return love.math.random(1, #cellinfo)
end

function BirdAPI.diagonalmoverbias(amount)
  return function(cell, dir, x, y, vars, side, force, ptype)
    if ptype == "push" then
      if side == 0 and not cell.frozen then cell.updated = cell.updated or not vars.noupdate return force - amount end
      if side == 2 and not cell.frozen then cell.updated = cell.updated or not vars.noupdate return force + amount end
      if side == 3 and not cell.frozen then cell.updated = cell.updated or not vars.noupdate return force - amount end
      if side == 1 and not cell.frozen then cell.updated = cell.updated or not vars.noupdate return force + amount end
    end
    return force
  end
end

function BirdAPI.pullerbias(amount)
  return function(cell, dir, x, y, vars, side, force, ptype)
    if ptype == "pull" then
      if side == 0 and not cell.frozen then cell.updated = cell.updated or not vars.noupdate return force - amount end
      if side == 2 and not cell.frozen then cell.updated = cell.updated or not vars.noupdate return force + amount end
    end
    return force
  end
end

function BirdAPI.DoMover(x,y,cell)
  return PushCell(x,y,cell.rot)
end

function BirdAPI.DoAdvancer(x,y,cell)
  local cx,cy,cdir = NextCell(x,y,(cell.rot+2)%4,getempty())
  cdir = (cdir+2)%4
  if PushCell(x,y,cell.rot) then
    PullCell(cx,cy,cdir,{force=1})
    return true
  else
    if PullCell(x,y,cell.rot) then
      return true
    end
  end
end

function BirdAPI.DoPuller(x,y,cell)
  return PullCell(x,y,cell.rot)
end

function BirdAPI.DoDiagMover(x,y,cell)
  local dir = cell.rot
  if PushCell(x,y,dir) then
    local cx,cy,cdir = NextCell(x,y,dir,getempty())
    PushCell(cx,cy,(cdir-1)%4)
  else
    PushCell(x,y,(dir-1)%4)
  end
end

function BirdAPI.DoSpecificDiagMover(x,y,cell,amount)
  local cx,cy,cdir = x,y,cell.rot
  for i = 1,amount do
    if PushCell(cx,cy,cdir) then
      cx,cy,cdir = NextCell(cx,cy,cdir,getempty())
      if PushCell(cx,cy,(cdir-1)%4) then
        cx,cy,cdir = NextCell(cx,cy,(cdir-1)%4,getempty())
        cdir = (cdir+1)%4
      end
    else
      if PushCell(cx,cy,(cdir-1)%4) then
        cx,cy,cdir = NextCell(cx,cy,(cdir-1)%4,getempty())
        cdir = (cdir+1)%4
      end
    end
  end
end

function BirdAPI.DoSpecificMover(x,y,cell,amount)
  local cx,cy = x,y
  local cdir = cell.rot
  for i = 1,amount do
    if PushCell(cx,cy,cdir) then
      cx,cy,cdir = NextCell(cx, cy, cdir, getempty())
    else
      return
    end
  end
end

function BirdAPI.DoSpecificPuller(x,y,cell,amount)
  local cx,cy = x,y
  local cdir = cell.rot
  for i = 1,amount do
    if PullCell(cx,cy,cdir) then
      cx,cy,cdir = NextCell(cx, cy, cdir, getempty())
    else
      return
    end
  end
end

function BirdAPI.DoSpecificAdvancer(x,y,cell,amount)
  local cx,cy = x,y
  local cdir = cell.rot
  for i = 1,amount do
    local bx,by,bdir = NextCell(cx,cy,(cdir+2)%4,getempty())
    bdir = (bdir+2)%4
    if PushCell(cx,cy,cdir) then
      PullCell(bx,by,bdir,{force=1})
    else
      if not PullCell(cx,cy,cdir) then
        return
      end
    end
    cx,cy,cdir = NextCell(cx, cy, cdir, getempty())
  end
end

function BirdAPI.UpdateSpecificAdvancer(amount)
  return function(x,y,cell)
    local cx,cy = x,y
    local cdir = cell.rot
    for i = 1,amount do
      local bx,by,bdir = NextCell(cx,cy,(cdir+2)%4,getempty())
      bdir = (bdir+2)%4
      if PushCell(cx,cy,cdir) then
        PullCell(bx,by,bdir,{force=1})
      else
        if not PullCell(cx,cy,cdir) then
          return
        end
      end
      cx,cy,cdir = NextCell(cx, cy, cdir, getempty())
    end
  end
end

function BirdAPI.UpdateSpecificPuller(amount)
  return function(x,y,cell)
    local cx,cy = x,y
    local cdir = cell.rot
    for i = 1,amount do
      if PullCell(cx,cy,cdir) then
        cx,cy,cdir = NextCell(cx, cy, cdir, getempty())
      else
        return
      end
    end
  end
end

function BirdAPI.UpdateSpecificMover(amount)
  return function(x,y,cell)
    local cx,cy = x,y
    local cdir = cell.rot
    for i = 1,amount do
      if PushCell(cx,cy,cdir) then
        cx,cy,cdir = NextCell(cx, cy, cdir, getempty())
      else
        return
      end
    end
  end
end

function BirdAPI.UpdateSpecificDiagMover(amount)
  return function(x,y,cell)
    local cx,cy,cdir = x,y,cell.rot
    for i = 1,amount do
      if PushCell(cx,cy,cdir) then
        cx,cy,cdir = NextCell(cx,cy,cdir,getempty())
        if PushCell(cx,cy,(cdir-1)%4) then
          cx,cy,cdir = NextCell(cx,cy,(cdir-1)%4,getempty())
          cdir = (cdir+1)%4
        end
      else
        if PushCell(cx,cy,(cdir-1)%4) then
          cx,cy,cdir = NextCell(cx,cy,(cdir-1)%4,getempty())
          cdir = (cdir+1)%4
        end
      end
    end
  end
end

function BirdAPI.expl(x,y,size,playsound,replacecell)
  replacecell = replacecell or getempty()
  playsound = playsound or false
  local destroyed = false
  for cx = x-size, x+size do
    for cy = y-size, y+size do
      if cx ~= x or cy ~= y then
        if GetCell(cx,cy).id ~= 0 then
          if not IsUnbreakable(GetCell(cx,cy),GetCell(cx,cy).rot,cx,cy,{forcetype="push",lastcell=getempty()}) then
            local lasts = table.copy(GetCell(cx,cy).lastvars)
            SetCell(cx,cy,table.copy(replacecell))
            GetCell(cx,cy).lastvars = lasts
            destroyed = true
          end
        end
      end
    end
  end
  if playsound and destroyed then
    Play(destroysound)
  end
  return destroyed
end

function BirdAPI.calculateCellPosition(x, y)
  local cx = math.floor((x+cam.x-400*winxm)/cam.zoom)
	local cy = math.floor((y+cam.y-300*winym)/cam.zoom)
  return {
    x = cx,
    y = cy
  }
end

function BirdAPI.calculateScreenPosition(x, y)
  local cx,cy = math.floor(x*cam.zoom-cam.x+cam.zoom*.5+400*winxm),math.floor(y*cam.zoom-cam.y+cam.zoom*.5+300*winym)
  return {
    x = cx,
    y = cy
  }
end


-- Multi-Update/Merge-Update/Multi-Bias

function BirdAPI.MultiBias(biases,amount)
  return function(cell, dir, x, y, vars, side, force, ptype)
    for k,v in ipairs(biases) do
      if type(BirdAPI[v.."bias"]) == "function" then
        force = BirdAPI[v.."bias"](amount or 1)(cell, dir, x, y, vars, side, force, ptype)
      end
    end
    return force
  end
end

function BirdAPI.MergeUpdate(updates)
  return function(x,y,cell)
    local cx,cy = x,y
    for k,v in ipairs(updates) do
      if type(MultiUpdate[v]) == "function" then
        MultiUpdate[v](x,y,cell)
      end
    end
  end
end

function BirdAPI.MultiUpdate(updates)
  return function(x,y,cell)
    for k,v in ipairs(updates) do
      if type(MultiUpdate[v]) == "function" then
        x,y,cell = MultiUpdate[v](x,y,cell)
      end
    end
  end
end

function MultiUpdate.mover(x,y,cell)
  if BirdAPI.DoMover(x,y,cell) then
    x,y = NextCell(x,y,cell.rot,getempty())
    cell = GetCell(x,y)
  end
  return x,y,cell
end

function MultiUpdate.gen(x,y,cell)
  BirdAPI.DoGenerator(x,y,cell.rot)
  return x,y,cell
end

function MultiUpdate.puller(x,y,cell)
  if BirdAPI.DoPuller(x,y,cell) then
    x,y = NextCell(x,y,cell.rot,getempty())
    cell = GetCell(x,y)
  end
  return x,y,cell
end

function MultiUpdate.advancer(x,y,cell)
  if BirdAPI.DoAdvancer(x,y,cell) then
    x,y = NextCell(x,y,cell.rot,getempty())
    cell = GetCell(x,y)
  end
  return x,y,cell
end

function MultiUpdate.replicator(x,y,cell)
  BirdAPI.DoGenerator(x,y,(cell.rot+2)%4,cell.rot)
end
