require 'table'
require 'test/unit'

class TestTableBasic < Test::Unit::TestCase
  def test_initialize
    t = Table.new
    assert_equal(["_itemid"], t.list_fields)
    t = Table.new %w[fruit color],
                  %w[apple red],
                  %w[banana yellow],
                  %w[orange orange]
    assert_equal(%w[_itemid fruit color].sort, t.list_fields.sort)
    a = t.to_a
    assert_operator(a, :include?, {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"})
    assert_operator(a, :include?, {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"})
    assert_operator(a, :include?, {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"})
    assert_equal(3, a.length)
  end

  def test_list_itemids
    t = Table.new
    assert_equal([], t.list_itemids)
    itemid1 = t.allocate_item
    assert_equal([itemid1], t.list_itemids)
    itemid2 = t.allocate_item
    assert_equal([itemid1, itemid2], t.list_itemids)
    assert_equal(nil, t.delete_item(itemid1))
    assert_equal([itemid2], t.list_itemids)
  end

  def test_cell
    t = Table.new %w[f g]
    itemid = t.allocate_item
    assert_equal(nil, t.get_cell(itemid, :f))
    t.set_cell(itemid, :f, 1)
    assert_equal(1, t.get_cell(itemid, :f))
    assert_equal(1, t.delete_cell(itemid, :f))
    assert_equal(nil, t.get_cell(itemid, :f))
    t.set_cell(itemid, :f, nil)
    assert_equal(nil, t.get_cell(itemid, :f))
    t.set_cell(itemid, :g, 2)
    assert_equal(2, t.get_cell(itemid, :g))
    t.set_cell(itemid, :g, nil)
    assert_equal(nil, t.get_cell(itemid, :g))
    t.delete_cell(itemid, :g)
    assert_equal(nil, t.get_cell(itemid, :g))
    t.delete_item(itemid)
    assert_raise(IndexError) { t.get_cell(itemid, :g) }
    assert_raise(IndexError) { t.get_cell(100, :g) }
    assert_raise(IndexError) { t.get_cell(-1, :g) }
    assert_raise(TypeError) { t.get_cell(:invalid_itemid, :g) }
  end

  def test_each_item
    t = Table.new %w[a], [1], [2]
    items = []
    t.each {|item| items << item }
    assert_equal([{"_itemid"=>0, "a"=>1}, {"_itemid"=>1, "a"=>2}], items)
  end

  def test_make_hash
    t = Table.new %w[a b c], [1,2,3], [2,4,4]
    assert_equal({1=>3, 2=>4}, t.make_hash("a", "c"))
    assert_equal({1=>[3], 2=>[4]}, t.make_hash("a", "c") {|seed, v| !seed ? [v] : (seed << v) })
    assert_equal({1=>1, 2=>1}, t.make_hash("a", "c") {|seed, v| !seed ? 1 : seed + 1 })
    assert_equal({1=>{2=>3}, 2=>{4=>4}}, t.make_hash("a", "b", "c"))
    t.insert({"a"=>2, "b"=>7, "c"=>8})
    assert_equal({1=>{2=>3}, 2=>{4=>4, 7=>8}}, t.make_hash("a", "b", "c"))
  end

  def test_make_hash_ambiguous
    t = Table.new %w[a b c], [1,2,3], [1,4,4]
    assert_raise(ArgumentError) { t.make_hash("a", "c") }
    assert_equal({1=>[3,4]}, t.make_hash("a", "c") {|seed, v| !seed ? [v] : (seed << v) })
    assert_equal({1=>2}, t.make_hash("a", "c") {|seed, v| !seed ? 1 : seed + 1 })
  end

  def test_natjoin2
    t1 = Table.new %w[a b], %w[1 2], %w[3 4], %w[0 4]
    t2 = Table.new %w[b c], %w[2 3], %w[4 5]
    t3 = t1.natjoin2(t2)
    assert_equal([{"_itemid"=>0, "a"=>"1", "b"=>"2", "c"=>"3"},
                  {"_itemid"=>1, "a"=>"3", "b"=>"4", "c"=>"5"},
                  {"_itemid"=>2, "a"=>"0", "b"=>"4", "c"=>"5"}], t3.to_a)
  end

  def test_fmap!
    t = Table.new %w[a b], %w[1 2], %w[3 4]
    t.fmap!("a") {|itemid, v| "foo" + v }
    assert_equal([{"_itemid"=>0, "a"=>"foo1", "b"=>"2"},
                  {"_itemid"=>1, "a"=>"foo3", "b"=>"4"}], t.to_a)
  end

  def test_delete_field
    t = Table.new(%w[a b], %w[1 2], %w[3 4])
    t.delete_field("a")
    assert_equal([{"_itemid"=>0, "b"=>"2"},
                  {"_itemid"=>1, "b"=>"4"}], t.to_a)
  end

  def test_delete_item
    t = Table.new %w[a]
    itemid = t.insert({"a"=>"foo"})
    t.insert({"a"=>"bar"})
    t.delete_item(itemid)
    t.insert({"a"=>"foo"})
    items = []
    t.each {|item|
      item.delete('_itemid')
      items << item
    }
    items = items.sort_by {|item| item['a'] }
    assert_equal([{"a"=>"bar"}, {"a"=>"foo"}], items)
  end

end
