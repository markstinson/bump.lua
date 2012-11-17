local geom = require 'bump.geom'

describe('bump.geom', function()
  describe('.boxesIntersect', function()
    it('returns true when two boxes geom', function()
      assert.truthy(geom.boxesIntersect(0,0,10,10, 5,5,10,10))
    end)
    it('returns false when two boxes do not geom', function()
      assert.falsy(geom.boxesIntersect(0,0,10,10, 20,20,10,10))
    end)
  end)

  describe('.boxesDisplacement', function()
    it('returns the minimum & total displacement vector needed to move box1 out of box2', function()
      assert.same({0,-6,-6,-6}, {geom.boxesDisplacement(0,0,10,10, 4,4,10,10)})
      assert.same({0,-4,-4,-4}, {geom.boxesDisplacement(0,0,10,10, 6,6,10,10)})
      assert.same({0,-5,-5,-5}, {geom.boxesDisplacement(0,0,10,10, 5,5,10,10)})
    end)
  end)

  describe('.boxSegmentIntersection', function()
    it('returns nothing if the segment and the box given are not intersecting', function()
      assert.Nil(geom.boxSegmentIntersection(0,0,20,20, 100,100, 200,200))
    end)
    it('returns 1 point if the segment only touches the border of the box', function()
      assert.same({0,0}, {geom.boxSegmentIntersection(0,0,20,20, 0,0, 0,-10)})
    end)
    it('returns 2 points if the segment goes through the box', function()
      assert.same({0,10, 20,10}, {geom.boxSegmentIntersection(0,0,20,20, -10,10, 30,10)})
    end)
  end)

  describe(".gridBox", function()
    it("returns nil if l is nil", function()
      assert.equal(nil, geom.gridBox())
    end)
    it("returns the l,t,w,h of the smallest grid box(coordinates of top-left grid, plus with and height, or 0,0) containing the given row", function()
      assert.same({1,1,0,0}, {geom.gridBox(64, 1,1,10,10)})
      assert.same({1,1,0,0}, {geom.gridBox(64, 1,1,10,63)})
      assert.same({1,1,0,1}, {geom.gridBox(64, 1,1,10,64)})
      assert.same({1,1,0,0}, {geom.gridBox(64, 1,0,10,10)})
    end)
  end)

  describe(".gridTraverse", function()
    local line
    function draw(x,y)
      line[#line + 1] = x
      line[#line + 1] = y
    end
    before_each(function()
      line = {}
    end)

    it('works', function()
      geom.gridTraverse(128, 515,515,76,263, draw)
      assert.same(line, {5,5, 4,5, 4,4, 3,4, 3,3, 2,3, 1,3})
    end)
    it('returns the number of cells crossed', function()
      assert.equal(geom.gridTraverse(128, 600, 128, 500, 512, draw), 5)
      assert.same(line, {5,2, 5,3, 5,4, 4,4, 4,5})
    end)
    it('jumps ok from cell to cell', function()
      geom.gridTraverse(128, 600, 127, 500, 512, draw)
      assert.same(line, {5,1, 5,2, 5,3, 5,4, 4,4, 4,5})
    end)

    describe('When the callback returns false', function()
      it('stops evaluating', function()
        local drawUntil44 = function(x,y)
          line[#line + 1] = x
          line[#line + 1] = y
          if x == 4 and y == 4 then return false end
        end
        assert.equal(geom.gridTraverse(128, 515,515,76,263, drawUntil44), 3)
        assert.same(line, {5,5, 4,5, 4,4})
      end)
      it('stops evaluating on the first cell too', function()
        local drawFirstOnly = function(x,y)
          line[#line + 1] = x
          line[#line + 1] = y
          return false
        end
        assert.equal(geom.gridTraverse(128, 515,515,76,263, drawFirstOnly), 1)
        assert.same(line, {5,5})
      end)
    end)
  end)
end)
