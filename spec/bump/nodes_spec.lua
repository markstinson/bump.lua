
local nodes = require 'bump.nodes'

describe("bump.nodes", function()

  before_each(nodes.reset)

  it("is a table", function()
    assert.equal(type(nodes), "table")
  end)

  describe(".get", function()
    it("returns nil for unknown items", function()
      assert.equal(nil, nodes.get({}))
    end)

    it("returns a node when the item is known", function()
      local item = {}
      nodes.add(item)
      assert.equal("table", type(nodes.get(item)))
    end)

  end)

  describe(".add", function()
    it("throws an error when passed nil", function()
      assert.error(function() nodes.add(nil) end)
    end)

    it("inserts new nodes in the list of nodes, but they get automatically gc", function()
      assert.equal(0, nodes.count())
      local item={}
      nodes.add(item)
      assert.equal(1, nodes.count())
      item = nil
      collectgarbage('collect')
      assert.equal(0, nodes.count())
    end)

    it("adds bounding, previous, affected boxes info & displacement info into the new node", function()
      local item = {}
      nodes.add(item, 1,2,3,4,5,6,7,8)
      local n = nodes.get(item)
      assert.same({n.l, n.t, n.w, n.h,
                   n.pl, n.pt, n.pw, n.ph,
                   n.dx, n.dy},
                  {1,2,3,4,1,2,3,4,0,0})
    end)

  end)

  describe(".count", function()
    it("returns the number of nodes available in the node store", function()
      assert.equal(0, nodes.count())
      nodes.add({})
      assert.equal(1, nodes.count())
    end)
  end)

  describe(".remove", function()
    it("destroys a node given its corresponding item", function()
      local item = {}
      nodes.add(item)
      assert.equal(1, nodes.count())
      nodes.remove(item)
      assert.equal(nil, nodes.get(item))
      assert.equal(0, nodes.count())
    end)
  end)

  describe(".eachItem", function()
    local a,b,c, na,nb,nc
    before_each(function()
      a,b,c = {},{},{}
      nodes.add(a, 1,2,3,4,5,6,7,8)
      nodes.add(b, 1,2,3,4,5,6,7,8)
      nodes.add(c, 1,2,3,4,5,6,7,8)
      na, nb, nc = nodes.get(a), nodes.get(b), nodes.get(c)
    end)
    it("It's called once per node and item", function()
      nodes.each(function(node, item)
        node.mark = true
        item.mark = true
      end)
      assert.same({true, true, true}, {a.mark, b.mark, c.mark})
      assert.same({true, true, true}, {na.mark, nb.mark, nc.mark})
    end)
    it("It stops when the callback returns false", function()
      local count = 0
      nodes.each(function(node, item)
        count = count + 1
        if count == 2 then return false end
      end)
      assert.equal(count, 2)
    end)

  end)

end)
