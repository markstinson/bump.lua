local bump = require 'bump.init'

describe("bump", function()

  before_each(function()
    bump.initialize()
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
      assert.equal(bump.countItems(), 0)
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
      assert.equal(bump.countItems(), 1)
    end)

    it("inserts the item in as many cells as needed", function()
      bump.add({l=1, t=1, w=70, h=70})
      assert.equal(bump.countCells(), 4)
    end)

    it("caches the bounding box info into the node", function()
      local item = {l=1, t=1, w=70, h=70}
      bump.add(item)
      local n = bump.nodes.get(item)
      assert.same({1,1,70,70,1,1,1,1}, {n.l,n.t,n.w,n.h, n.gl,n.gt,n.gw,n.gh})
    end)
  end)
end)