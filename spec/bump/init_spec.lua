require 'spec.assert_has_value'

local function xit() end
local function xdescribe() end

local bump = require 'bump.init'

describe("bump", function()

  local defaultCollision      = bump.collision
  local defaultEndCollision   = bump.endCollision
  local defaultShouldCollide  = bump.shouldCollide
  local defaultGetBBox        = bump.getBBox

  before_each(function()
    bump.initialize()
    bump.collision      = defaultCollision
    bump.endCollision   = defaultEndCollision
    bump.shouldCollide  = defaultShouldCollide
    bump.getBBox        = defaultGetBBox
  end)

  it("is a table", function()
    assert.equal(type(bump), "table")
  end)

  describe(".initialize", function()
    it("is a function", function()
      assert.equal(type(bump.initialize), "function")
    end)
    it("sets the cell size", function()
      bump.initialize(32)
      assert.equal(32, bump:getCellSize())
    end)
    it("defaults the cell size to 64", function()
      bump.initialize()
      assert.equal(64, bump:getCellSize())
    end)
    it("sets the item count back to 0", function()
      bump.add({l=1, t=1, w=1, h=1})
      bump.initialize()
      assert.equal(bump.nodes.count(), 0)
    end)
  end)

  describe(".getBBox", function()
    it("obtains the bounding box by getting the l,t,w,h properties by default", function()
      assert.same({1,2,3,4}, { bump.getBBox({ l=1, t=2, w=3, h=4 }) })
    end)
  end)

  describe(".add", function()
    it("raises an error if nil is passed", function()
      assert.error(function() bump.add() end)
    end)

    it("increases the item count by 1", function()
      bump.add({l=1, t=2, w=3, h=4})
      assert.equal(bump.nodes.count(), 1)
    end)

    it("inserts the item in as many cells as needed", function()
      bump.add({l=1, t=1, w=70, h=70})
      assert.equal(bump.cells.count(), 4)
    end)

    it("caches the bounding box info into the node", function()
      local item = {l=1, t=1, w=70, h=70}
      bump.add(item)
      local n = bump.nodes.get(item)
      assert.same({ 1,1,70,70,
                    1,1,70,70,
                    1,1,1,1,
                    0,0
                   }, {
                     n.l,n.t,n.w,n.h,
                     n.pl,n.pt,n.pw,n.ph,
                     n.al,n.at,n.aw,n.ah,
                     n.dx,n.dy
                   })
    end)

    it("can add more than one item in one go", function()
      local item1 = {l=1, t=1, w=70, h=70}
      local item2 = {l=100, t=100, w=70, h=70}
      bump.add(item1, item2)
      assert.truthy(bump.nodes.get(item1))
      assert.truthy(bump.nodes.get(item2))
    end)
  end)

  describe(".remove", function()
    it("raises an error if nil is passed", function()
      assert.error(function() bump.remove() end)
    end)

    it("decreases the item count by 1", function()
      local item = {l=1, t=2, w=3, h=4}
      bump.add(item)
      bump.remove(item)
      assert.equal(bump.nodes.count(), 0)
    end)

    it("removes the item from as many cells as needed", function()
      local item = {l=1, t=2, w=70, h=70}
      bump.add(item)
      bump.remove(item)
      collectgarbage('collect')
      assert.equal(bump.cells.count(), 0)
    end)
  end)

  describe(".update", function()

    it("does nothing if the bbox has not changed", function()
      local item = {l=1, t=2, w=3, h=4}
      bump.add(item)
      spy.on(bump.nodes, 'update')
      spy.on(bump.cells, 'remove')
      bump.update(item)
      assert.spy(bump.nodes.update).was_not_called()
      assert.spy(bump.cells.remove).was_not_called()
    end)

    it("updates the previous position even if the item has not moved", function()
      local item = {l=1, t=2, w=3, h=4}
      bump.add(item)
      item.l, item.t, item.w, item.h = 5,6,7,8
      bump.update(item)
      bump.update(item)
      local n = bump.nodes.get(item)
      assert.same({ n.pl, n.pt, n.pw, n.ph, n.dx, n.dy }, {5,6,7,8, 0,0})
    end)

    it("updates the node if the bbox has changed", function()
      local item = {l=0, t=0, w=1, h=1}
      bump.add(item)
      local node = bump.nodes.get(item)
      item.l, item.t, item.w, item.h = 10,20,70,70
      bump.update(item)
      local n = bump.nodes.get(item)
      assert.same({ n.l, n.t, n.w, n.h },     { 10, 20, 70, 70 })
      assert.same({ n.pl, n.pt, n.pw, n.ph }, {  0,  0,  1,  1 })
      assert.same({ n.al, n.at, n.aw, n.ah }, {  1,  1,  1,  1 })
      assert.same({ n.dx, n.dy },             { -44.5, -54.5 })
    end)

    it("updates the cells if the grid bbox has changed", function()
      local item = {l=1, t=2, w=3, h=4}

      bump.add(item)
      assert.truthy(bump.cells.getOrCreate(1,1).items[item])

      item.l, item.t, item.w, item.h = 100, 100, 60, 60
      bump.update(item)
      assert.truthy(bump.cells.getOrCreate(1,1).items[item])
      assert.truthy(bump.cells.getOrCreate(1,2).items[item])
      assert.truthy(bump.cells.getOrCreate(1,3).items[item])
      assert.truthy(bump.cells.getOrCreate(2,1).items[item])
      assert.truthy(bump.cells.getOrCreate(2,2).items[item])
      assert.truthy(bump.cells.getOrCreate(2,3).items[item])
      assert.truthy(bump.cells.getOrCreate(3,1).items[item])
      assert.truthy(bump.cells.getOrCreate(3,2).items[item])
      assert.truthy(bump.cells.getOrCreate(3,3).items[item])

      bump.update(item)
      assert.falsy( bump.cells.getOrCreate(1,1).items[item])
      assert.falsy( bump.cells.getOrCreate(1,2).items[item])
      assert.falsy( bump.cells.getOrCreate(1,3).items[item])
      assert.falsy( bump.cells.getOrCreate(2,1).items[item])
      assert.truthy(bump.cells.getOrCreate(2,2).items[item])
      assert.truthy(bump.cells.getOrCreate(2,3).items[item])
      assert.falsy( bump.cells.getOrCreate(3,1).items[item])
      assert.truthy(bump.cells.getOrCreate(3,2).items[item])
      assert.truthy(bump.cells.getOrCreate(3,3).items[item])
    end)
  end)

  describe(".each and .eachInRegion", function()
    local i11, i12, i21, i22, count

    local function mark(item)
      count = count + 1
      item.mark = true
    end

    local function countTill2()
      count = count + 1
      if count == 2 then return false end
    end

    before_each(function()
      count = 0
      i11 = {l=1, t=1,  w=1, h=1}
      i12 = {l=80,t=1,  w=1, h=1}
      i21 = {l=1, t=80, w=1, h=1}
      i22 = {l=80,t=80, w=1, h=1}
      bump.add(i11, i12, i21, i22)
    end)

    describe(".each", function()
      it("affects all items", function()
        bump.each(mark)
        assert.same({true, true, true, true}, {i11.mark, i12.mark, i21.mark, i22.mark})
      end)

      it("executes the callback function only once per item, even if they touch several cells", function()
        local big = {l=1, t=1, w=80, h=1}
        bump.add(big)
        bump.each(mark)
        assert.equal(5, count)
      end)

      it("allows removing items without raising errors", function()
        local removeItem12 = function(item)
          if item == item12 then bump.remove(item) end
        end
        assert.Not.error(function() bump.each(removeItem12) end)
      end)

      it("stops if the callback returns false", function()
        bump.each(countTill2)
        assert.equal(count, 2)
      end)
    end)

    describe(".eachInRegion", function()
      it("affects only the items inside that box", function()
        bump.eachInRegion(0,0,20,20, mark)
        assert.same({true}, {i11.mark, i12.mark, i21.mark, i22.mark})
      end)
      it("does not affect the items inside the grid box, but outside the specified box", function()
        bump.eachInRegion(0,0,70,20, mark)
        assert.same({true}, {i11.mark, i12.mark, i21.mark, i22.mark})
      end)
      it("stops if the callback returns false", function()
        bump.eachInRegion(0,0,100,100, countTill2)
        assert.equal(count, 2)
      end)
    end)
  end)

  describe("bump.eachInSegment", function()
    local intersections, counter
    local mark = function(item, x, y)
      if not item.mark then
        counter = counter + 1
        item.mark = counter
      end

      local len  = #intersections
      intersections[len+1], intersections[len+2] = x,y
    end

    before_each(function()
      intersections = {}
      counter = 0
    end)

    it("does nothing if bump is empty", function()
      assert.Not.error(function() bump.eachInSegment(0,0,10,10, mark) end)
    end)

    it("does nothing if the segment does not intersect with anything", function()
      local item = {l=20,t=20,w=1,h=1}
      bump.add(item)
      bump.eachInSegment(0,0,10,10, mark)
      assert.falsy(item.mark)
    end)

    describe("When there are items in bump", function()
      local item1, item2, item3, item4
      before_each(function()
        item1 = {l=20,  t=0,  w=10, h=10}
        item2 = {l=40,  t=0,  w=10, h=10}
        item3 = {l=100, t=0,  w=10, h=10}
        item4 = {l=20,  t=100, w=10, h=10}
        bump.add(item1, item2, item3, item4)
      end)

      it("parses the items in the right order", function()
        bump.eachInSegment(0,5, 200,5, mark)
        assert.same({1,2,3}, {item1.mark, item2.mark, item3.mark, item4.mark})
      end)

      it("parses the items in reverse order", function()
        bump.eachInSegment(200,5, 0,5, mark)
        assert.same({3,2,1}, {item1.mark, item2.mark, item3.mark, item4.mark})
      end)

      it("returns intersections in the right order", function()
        bump.eachInSegment(0,5, 80,5, mark)
        assert.same(intersections, {20,5, 30,5, 40,5, 50,5})
      end)

      it("stops parsing if the callback returns false", function()
        local stopOn2 = function(item)
          mark(item)
          if item == item2 then return false end
        end
        bump.eachInSegment(0,5, 200,5, stopOn2)
        assert.same({1,2}, {item1.mark, item2.mark, item3.mark, item4.mark})
      end)
    end)

  end)

  describe("bump.collision and bump.collide", function()

    it("is empty by efault", function()
      assert.equal(type(bump.collision), "function")
    end)

    describe("bump.collide's only param", function()
      local item = {l=1,t=1,w=1,h=1}
      before_each(function()
        spy.on(bump, "update")
        bump.add(item)
      end)
      it("triggers a global item update by default", function()
        bump.collide()
        assert.spy(bump.update).was.called_with(item)
      end)
      it("triggers a global item update if true", function()
        bump.collide(true)
        assert.spy(bump.update).was.called_with(item)
      end)
      it("does not trigger a global item update if false", function()
        bump.collide(false)
        assert.spy(bump.update).was.Not.called()
      end)
    end)

    describe("When bump.collision is defined", function()
      local collisions
      before_each(function()
        collisions = {}
        bump.collision = function(i1,i2, dx1, dy1, dx2, dy2, t)
          collisions[#collisions + 1] = {i1.name, i2.name, dx1, dy1, dx2, dy2, t}
        end
      end)

      it("is never called if there are no items to collide", function()
        bump.collide()
        assert.empty(collisions)
      end)

      describe("When items don't move relatively", function()

        it("is called if two items collide", function()
          local item1 = {l=0,t=0,w=10,h=10, name='item1'}
          local item2 = {l=4,t=4,w=10,h=10, name='item2'}
          bump.add(item1, item2)
          bump.shouldCollide = function(a,b) return a == item1 end

          bump.collide()
          assert.same({{'item1', 'item2',0,-6,0,0,0}}, collisions)
        end)

        it("is called only once per pair (not twice)", function()
          local counter = 0
          bump.collision = function() counter = counter + 1 end

          local item1 = {l=0,t=0,w=10,h=10, name='item1'}
          local item2 = {l=4,t=4,w=10,h=10, name='item2'}
          bump.add(item1, item2)

          bump.collide()
          assert.equals(counter,1)

        end)

        it("invokes collisions with less displacement first", function()
          local item1 = {l=1,t=1,w=10,h=10, name='item1'}
          local item2 = {l=2,t=2,w=10,h=10, name='item2'}
          local item3 = {l=3,t=3,w=10,h=10, name='item3'}
          local item4 = {l=4,t=4,w=10,h=10, name='item4'}
          bump.add(item1, item2, item3, item4)
          bump.shouldCollide = function(a,b) return a == item1 end

          bump.collide()
          assert.same({
            {'item1','item4',0,-7,0,0,0},
            {'item1','item3',0,-8,0,0,0},
            {'item1','item2',0,-9,0,0,0}
          }, collisions)
        end)
      end)

      describe("When items move", function()

        describe("And they are already intersecting", function()
          it("can throw already intersecting item forwards", function()
            local item1 = {l=1,t=1,w=10,h=10, name='item1'}
            local item2 = {l=2,t=2,w=10,h=10, name='item2'}
            bump.add(item1, item2)
            bump.shouldCollide = function(a,b) return a == item1 end

            item1.l = 5

            bump.collide()
            assert.same({{'item1','item2',7,0,0,0,-1.75}}, collisions)
          end)

          it("can throw already intersecting item backwards", function()
            local item1 = {l=1,t=1,w=10,h=10, name='item1'}
            local item2 = {l=2,t=2,w=40,h=10, name='item2'}
            bump.add(item1, item2)
            bump.shouldCollide = function(a,b) return a == item1 end

            item1.l = 10

            bump.collide()
            assert.same({{'item1','item2',-18,0,0,0,2}}, collisions)
          end)
        end)

        describe("When they are not already intersecting", function()
          it("throws both items backwards a little, if both were moving", function()
            local item1 = {l=0, t=0,  w=10,h=10, name='item1'}
            local item2 = {l=20,t=20, w=10,h=10, name='item2'}
            bump.add(item1, item2)
            bump.shouldCollide = function(a,b) return a == item1 end

            item1.l, item1.t, item2.l, item2.t = 20,20, 0,0

            bump.collide()
            assert.same({{'item1','item2',-5,-5,5,5, 0.25}}, collisions)
          end)

          it("fires intersections sorted by t", function()
            local item1 = {l=0, t=0,  w=10,h=10, name='item1'}
            local item2 = {l=20,t=20, w=20,h=10, name='item2'}
            local item3 = {l=40,t=10, w=30,h=10, name='item3'}
            bump.add(item1, item2, item3)

            item1.l, item1.t = 30,10
            item2.l, item2.t = 10,25
            item3.l, item3.t = 30,20

            bump.collide()
            assert.same({
              {'item3','item1',2.5,-2.5,-7.5,-2.5,0.25},
              {'item2','item3',10,-5,10,-10,1}
            }, collisions)

          end)
        end)
      end)
    end)

    xdescribe("when bump.collide triggers the removal of one item", function()
      local item1, item2, item3, item4
      before_each(function()
        item1 = {l=1,t=1,w=10,h=10, name='item1'}
        item2 = {l=2,t=2,w=10,h=10, name='item2'}
        item3 = {l=3,t=3,w=10,h=10, name='item3'}
        item4 = {l=4,t=4,w=10,h=10, name='item4'}
        bump.add(item1, item2, item3, item4)
      end)

      it("allows removing first item", function()
        bump.collision = function(item1, item2) bump.remove(item1) end
        assert.Not.error(bump.collide)
      end)
      it("allows removing second item", function()
        bump.collision = function(item1, item2) bump.remove(item2) end
        assert.Not.error(bump.collide)
      end)
      it("allows removing both items", function()
        bump.collision = function(item1, item2)
          bump.remove(item1)
          bump.remove(item2)
        end
        assert.Not.error(bump.collide)
      end)
    end)
  end)

  xdescribe(".shouldCollide", function()
    it("returns true by default", function()
      assert.truthy(bump.shouldCollide())
    end)
    describe("When defined", function()
      it("conditions which objects collide and which ones don't", function()
        local item1 = {l=1,t=1,w=10,h=10, name='item1'}
        local item2 = {l=2,t=2,w=10,h=10, name='item2'}
        local item3 = {l=3,t=3,w=10,h=10, name='item3'}
        local item4 = {l=4,t=4,w=10,h=10, name='item4'}
        bump.add(item1, item2, item3, item4)

        bump.shouldCollide = function(a, b)
          return a == item1 or b == item1
        end
        local counter = 0
        bump.collision = function(item1, item2, dx, dy)
          counter = counter + 1
        end
        bump.collide()
        assert.equals(counter, 3) -- instead of 6
      end)
    end)
  end)

  xdescribe('.endCollision', function()
    local endedCollisions
    before_each(function()
      endedCollisions = {}
      bump.endCollision = function(item1, item2)
        endedCollisions[#endedCollisions + 1] = {item1.name, item2.name}
      end
    end)

    it("is not called when no collisions happen", function()
      bump.collide()
      assert.empty(endedCollisions)
    end)

    describe("when collisions do happen", function()
      local item1, item2, item3
      before_each(function()
        item1 = {l=1,t=1,w=20,h=20, name='item1'}
        item2 = {l=2,t=2,w=10,h=10, name='item2'}
        item3 = {l=3,t=3,w=10,h=10, name='item3'}
        bump.add(item1, item2, item3)
        bump.shouldCollide = function(a,b) return a == item1 end
      end)

      it("is called once for each pair of items which are not colliding any more", function()
        bump.collide()
        assert.empty(endedCollisions)
        item1.l, item1.t = 100,100
        bump.update(item1)
        bump.collide()
        assert.same(#endedCollisions, 2)
        assert.has_value(endedCollisions[1], 'item1')
        assert.has_value(endedCollisions[2], 'item1')
      end)
    end)
  end)
end)
