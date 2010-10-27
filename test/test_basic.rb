require 'table'
require 'test/unit'

class TestTableBasic < Test::Unit::TestCase
  def test_list_rowids
    t = Table.new
    assert_equal([], t.list_rowids)
    rowid1 = t.allocate_rowid
    assert_equal([rowid1], t.list_rowids)
    rowid2 = t.allocate_rowid
    assert_equal([rowid1, rowid2], t.list_rowids)
    assert_equal({"_rowid"=>rowid1}, t.delete_row(rowid1))
    assert_equal([rowid2], t.list_rowids)
  end

  def test_cell
    t = Table.new
    rowid = t.allocate_rowid
    assert_equal(nil, t.get_cell(rowid, :f))
    t.set_cell(rowid, :f, 1)
    assert_equal(1, t.get_cell(rowid, :f))
    t.delete_cell(rowid, :f)
    assert_equal(nil, t.get_cell(rowid, :f))
    t.set_cell(rowid, :f, nil)
    assert_equal(nil, t.get_cell(rowid, :f))
    t.set_cell(rowid, :g, 2)
    assert_equal(2, t.get_cell(rowid, :g))
    t.set_cell(rowid, :g, nil)
    assert_equal(nil, t.get_cell(rowid, :g))
    t.delete_cell(rowid, :g)
    assert_equal(nil, t.get_cell(rowid, :g))
    assert_equal(nil, t.get_cell(100, :g))
    assert_raise(IndexError) { t.get_cell(-1, :g) }
    assert_raise(IndexError) { t.get_cell(:invalid_rowid, :g) }
  end

  def test_make_hash
    t = Table.new
    t.insert({"a"=>1, "b"=>2, "c"=>3})
    t.insert({"a"=>2, "b"=>4, "c"=>4})
    assert_equal({1=>3, 2=>4}, t.make_hash("a", "c"))
    assert_equal({1=>[3], 2=>[4]}, t.make_hash("a", "c") {|seed, v| !seed ? [v] : (seed << v) })
    assert_equal({1=>1, 2=>1}, t.make_hash("a", "c") {|seed, v| !seed ? 1 : seed + 1 })
    assert_equal({1=>{2=>3}, 2=>{4=>4}}, t.make_hash("a", "b", "c"))
    t.insert({"a"=>2, "b"=>7, "c"=>8})
    assert_equal({1=>{2=>3}, 2=>{4=>4, 7=>8}}, t.make_hash("a", "b", "c"))
  end

  def test_make_hash_ambiguous
    t = Table.new
    t.insert({"a"=>1, "b"=>2, "c"=>3})
    t.insert({"a"=>1, "b"=>4, "c"=>4})
    assert_raise(ArgumentError) { t.make_hash("a", "c") }
    assert_equal({1=>[3,4]}, t.make_hash("a", "c") {|seed, v| !seed ? [v] : (seed << v) })
    assert_equal({1=>2}, t.make_hash("a", "c") {|seed, v| !seed ? 1 : seed + 1 })
  end

end
