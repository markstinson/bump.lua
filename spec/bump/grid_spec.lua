local grid = require 'bump.grid'

describe('bump.grid', function()
  it('is a table', function()
    assert.equal(type(grid), 'table')
  end)

  describe(".getBox", function()
    it("returns nil if l is nil", function()
      assert.equal(nil, grid.getBox())
    end)
    it("returns the l,t,w,h of the smallest grid box(coordinates of top-left grid, plus with and height, or 0,0) containing the given row", function()
      assert.same({1,1,0,0}, {grid.getBox(64, 1,1,10,10)})
      assert.same({1,1,0,0}, {grid.getBox(64, 1,1,10,63)})
      assert.same({1,1,0,1}, {grid.getBox(64, 1,1,10,64)})
      assert.same({1,1,0,0}, {grid.getBox(64, 1,0,10,10)})
    end)
  end)

  describe(".traverse", function()
    local line
    function draw(x,y)
      line[#line + 1] = x
      line[#line + 1] = y
    end
    before_each(function()
      line = {}
    end)

    it('works', function()
      grid.traverse(128, 515,515,76,263, draw)
      assert.same(line, {5,5, 4,5, 4,4, 3,4, 3,3, 2,3, 1,3})
    end)
    it('returns the number of cells crossed', function()
      assert.equal(grid.traverse(128, 600, 128, 500, 512, draw), 5)
      assert.same(line, {5,2, 5,3, 5,4, 4,4, 4,5})
    end)
    it('jumps ok from cell to cell', function()
      grid.traverse(128, 600, 127, 500, 512, draw)
      assert.same(line, {5,1, 5,2, 5,3, 5,4, 4,4, 4,5})
    end)

    describe('When the callback returns false', function()
      it('stops evaluating', function()
        local drawUntil44 = function(x,y)
          line[#line + 1] = x
          line[#line + 1] = y
          if x == 4 and y == 4 then return false end
        end
        assert.equal(grid.traverse(128, 515,515,76,263, drawUntil44), 3)
        assert.same(line, {5,5, 4,5, 4,4})
      end)
      it('stops evaluating on the first cell too', function()
        local drawFirstOnly = function(x,y)
          line[#line + 1] = x
          line[#line + 1] = y
          return false
        end
        assert.equal(grid.traverse(128, 515,515,76,263, drawFirstOnly), 1)
        assert.same(line, {5,5})
      end)
    end)
  end)
end)
