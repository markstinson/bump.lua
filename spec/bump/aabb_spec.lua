local aabb = require 'bump.aabb'

local function xdescribe() end
local function xit() end

describe('bump.aabb', function()
  it('is a table', function()
    assert.equal(type(aabb), 'table')
  end)

  describe('.isIntersecting', function()
    it('returns true when two aabbes geom', function()
      assert.truthy(aabb.isIntersecting(0,0,10,10, 5,5,10,10))
    end)
    it('returns false when two aabbes do not geom', function()
      assert.falsy(aabb.isIntersecting(0,0,10,10, 20,20,10,10))
    end)
  end)

  describe('.containsPoint', function()
    it('returns true if a point is inside the box', function()
      assert.True(aabb.containsPoint(0,0,10,10, 5,5))
    end)
    it('returns false if a point is outside the box', function()
      assert.False(aabb.containsPoint(0,0,10,10, 15,15))
    end)
  end)

  describe('.getMinkowskyDiff', function()
    it('returns the Minkowsky difference of two given boxes', function()
      assert.same({-100,10,320,260}, {aabb.getMinkowskyDiff(10,60,150,120, 60,190,170,140)})
      assert.same({-98,-42,320,260}, {aabb.getMinkowskyDiff(8,112,150,120, 60,190,170,140)})
    end)
  end)

  describe('.getNearestPointInPerimeter', function()
    it('returns the x,y coordinates of the nearest point in the perimeter of the aabb to a given point', function()
      assert.same({10,10}, {aabb.getNearestPointInPerimeter(0,0,10,10, 15,15)})
      assert.same({0,10}, {aabb.getNearestPointInPerimeter(0,0,10,10, 4,15)})
      assert.same({10,10}, {aabb.getNearestPointInPerimeter(0,0,10,10, 15,7)})
      assert.same({0,10}, {aabb.getNearestPointInPerimeter(0,0,10,10, -2,15)})
      assert.same({0,0}, {aabb.getNearestPointInPerimeter(0,0,10,10, -1,2)})
    end)
  end)

  describe('.getPointDisplacement', function()
    it('returns minimum displacement vector needed to move aabb so that it has the point on its perimeter', function()
      -- point is inside aabb
      assert.same({3,0}, {aabb.getPointDisplacement(0,0,10,10, 3,4)})
      assert.same({0,4}, {aabb.getPointDisplacement(0,0,10,10, 6,4)})
      assert.same({0,-5}, {aabb.getPointDisplacement(0,0,10,10, 5,5)})

      -- point is outside aabb
      assert.same({0,10}, {aabb.getPointDisplacement(0,0,10,10, 20,20)})
      assert.same({0,15}, {aabb.getPointDisplacement(0,0,10,10, 30,25)})

      -- point is in perimeter
      assert.same({0,0}, {aabb.getPointDisplacement(0,0,10,10, 0,0)})

    end)
  end)

  describe('.getDisplacement', function()

    describe('when the two aabbs are relatively static', function()
      it('returns the minimum & total displacement vector needed to move aabb1 out of aabb2', function()
        assert.same({0,-6, 0,0,0}, {aabb.getDisplacement(0,0,10,10,0,0, 4,4,10,10, 0,0)})
        assert.same({0,-4, 0,0,0}, {aabb.getDisplacement(0,0,10,10,0,0, 6,6,10,10, 0,0)})
        assert.same({0,-5, 0,0,0}, {aabb.getDisplacement(0,0,10,10,0,0, 5,5,10,10, 0,0)})
      end)
      it('returns nil if the two aabbs are not intersecting', function()
        assert.empty({aabb.getDisplacement(0,0,10,10,0,0, 20,20,10,10,0,0)})
      end)
    end)

  end)

  describe('.getRayIntersection', function()
    it('returns nothing if the ray and the aabb are not intersecting', function()
      assert.True(nil == aabb.getRayIntersection(0,0,20,20, 100,100, 200,200))
    end)
    it('returns 2 points if the segment goes through the aabb', function()
      assert.same({0,10, 20,10}, {aabb.getRayIntersection(0,0,20,20, -10,10, 30,10)})
    end)
    it('returns the origin and 1 poing if the ray starts inside the aabb', function()
      assert.same({5,10, 20,10}, {aabb.getRayIntersection(0,0,20,20, 5,10, 30,10)})
    end)
  end)

  describe('.getSegmentIntersection', function()
    it('returns nothing if the segment and the aabb given are not intersecting', function()
      assert.True(nil == aabb.getSegmentIntersection(0,0,20,20, 100,100, 200,200)) end)
    it('returns the same point twice if the segment only touches the border of the aabb', function()
      assert.same({0,0,0,0}, {aabb.getSegmentIntersection(0,0,20,20, 0,0, 0,-10)})
    end)
    it('returns 2 points if the segment goes through the aabb', function()
      assert.same({0,10, 20,10}, {aabb.getSegmentIntersection(0,0,20,20, -10,10, 30,10)})
    end)
  end)

  describe('.getCenter', function()
    it("returns the center of an aabb", function()
      assert.same({0,0}, {aabb.getCenter(0,0,0,0)})
      assert.same({1,1}, {aabb.getCenter(0,0,2,2)})
      assert.same({2,0}, {aabb.getCenter(0,0,4,0)})
      assert.same({1,3}, {aabb.getCenter(0,0,2,6)})
    end)
  end)
end)
