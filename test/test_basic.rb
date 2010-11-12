require 'table'
require 'test/unit'

class TestTableBasic < Test::Unit::TestCase
  def test_initialize
    t = Table.new
    assert_equal(["_recordid"], t.list_fields)
    t = Table.new %w[fruit color],
                  %w[apple red],
                  %w[banana yellow],
                  %w[orange orange]
    assert_equal(%w[_recordid fruit color].sort, t.list_fields.sort)
    a = t.to_a.map {|r| r.to_h }
    assert_operator(a, :include?, {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"})
    assert_operator(a, :include?, {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"})
    assert_operator(a, :include?, {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"})
    assert_equal(3, a.length)
  end

  def test_list_recordids
    t = Table.new
    assert_equal([], t.list_recordids)
    recordid1 = t.allocate_recordid
    assert_equal([recordid1], t.list_recordids)
    recordid2 = t.allocate_recordid
    assert_equal([recordid1, recordid2], t.list_recordids)
    assert_equal(nil, t.delete_record(recordid1))
    assert_equal([recordid2], t.list_recordids)
  end

  def test_cell
    t = Table.new %w[f g]
    recordid = t.allocate_recordid
    assert_equal(nil, t.get_cell(recordid, :f))
    t.set_cell(recordid, :f, 1)
    assert_equal(1, t.get_cell(recordid, :f))
    assert_equal(1, t.delete_cell(recordid, :f))
    assert_equal(nil, t.get_cell(recordid, :f))
    t.set_cell(recordid, :f, nil)
    assert_equal(nil, t.get_cell(recordid, :f))
    t.set_cell(recordid, :g, 2)
    assert_equal(2, t.get_cell(recordid, :g))
    t.set_cell(recordid, :g, nil)
    assert_equal(nil, t.get_cell(recordid, :g))
    t.delete_cell(recordid, :g)
    assert_equal(nil, t.get_cell(recordid, :g))
    t.delete_record(recordid)
    assert_raise(IndexError) { t.get_cell(recordid, :g) }
    assert_raise(IndexError) { t.get_cell(100, :g) }
    assert_raise(IndexError) { t.get_cell(-1, :g) }
    assert_raise(TypeError) { t.get_cell(:invalid_recordid, :g) }
  end

  def test_each_field
    t = Table.new %w[a b z]
    a = []
    t.each_field {|f| a << f }
    assert_equal(%w[_recordid a b z], a)
  end

  def test_each_record
    t = Table.new %w[a], [1], [2]
    records = []
    t.each {|record| records << record.to_h }
    assert_equal([{"_recordid"=>0, "a"=>1}, {"_recordid"=>1, "a"=>2}], records)
  end

  def test_categorize
    t = Table.new %w[a b c], [1,2,3], [2,4,4]
    assert_equal({1=>3, 2=>4}, t.unique_categorize("a", "c"))
    assert_equal({1=>[3], 2=>[4]}, t.unique_categorize("a", "c") {|seed, v| !seed ? [v] : (seed << v) })
    assert_equal({1=>1, 2=>1}, t.unique_categorize("a", "c") {|seed, v| !seed ? 1 : seed + 1 })
    assert_equal({1=>{2=>3}, 2=>{4=>4}}, t.unique_categorize("a", "b", "c"))
    t.insert({"a"=>2, "b"=>7, "c"=>8})
    assert_equal({1=>{2=>3}, 2=>{4=>4, 7=>8}}, t.unique_categorize("a", "b", "c"))
  end

  def test_categorize_ambiguous
    t = Table.new %w[a b c], [1,2,3], [1,4,4]
    assert_raise(ArgumentError) { t.unique_categorize("a", "c") }
    assert_equal({1=>[3,4]}, t.unique_categorize("a", "c") {|seed, v| !seed ? [v] : (seed << v) })
    assert_equal({1=>2}, t.unique_categorize("a", "c") {|seed, v| !seed ? 1 : seed + 1 })
  end

  def test_natjoin2
    t1 = Table.new %w[a b], %w[1 2], %w[3 4], %w[0 4]
    t2 = Table.new %w[b c], %w[2 3], %w[4 5]
    t3 = t1.natjoin2(t2)
    assert_equal([{"_recordid"=>0, "a"=>"1", "b"=>"2", "c"=>"3"},
                  {"_recordid"=>1, "a"=>"3", "b"=>"4", "c"=>"5"},
                  {"_recordid"=>2, "a"=>"0", "b"=>"4", "c"=>"5"}], t3.to_a.map {|r| r.to_h })
  end

  def test_fmap!
    t = Table.new %w[a b], %w[1 2], %w[3 4]
    t.fmap!("a") {|recordid, v| "foo" + v }
    assert_equal([{"_recordid"=>0, "a"=>"foo1", "b"=>"2"},
                  {"_recordid"=>1, "a"=>"foo3", "b"=>"4"}], t.to_a.map {|r| r.to_h })
  end

  def test_delete_field
    t = Table.new(%w[a b], %w[1 2], %w[3 4])
    t.delete_field("a")
    assert_equal([{"_recordid"=>0, "b"=>"2"},
                  {"_recordid"=>1, "b"=>"4"}], t.to_a.map {|r| r.to_h })
  end

  def test_delete_record
    t = Table.new %w[a]
    recordid = t.insert({"a"=>"foo"})
    t.insert({"a"=>"bar"})
    t.delete_record(recordid)
    t.insert({"a"=>"foo"})
    records = []
    t.each {|record|
      record = record.to_h
      record.delete('_recordid')
      records << record
    }
    records = records.sort_by {|record| record['a'] }
    assert_equal([{"a"=>"bar"}, {"a"=>"foo"}], records)
  end

  def test_rename_field
    t1 = Table.new %w[a b], [1, 2]
    assert_equal([{"_recordid"=>0, "a"=>1, "b"=>2}], t1.to_a.map {|r| r.to_h })
    t2 = t1.rename_field("a" => "c", "b" => "d")
    assert_equal([{"_recordid"=>0, "a"=>1, "b"=>2}], t1.to_a.map {|r| r.to_h })
    assert_equal([{"_recordid"=>0, "c"=>1, "d"=>2}], t2.to_a.map {|r| r.to_h })
  end

  def test_allocate_recordid
    t = Table.new
    recordid1 = t.allocate_recordid(100)
    assert_equal(100, recordid1)
    recordid2 = t.allocate_recordid(200)
    assert_equal(200, recordid2)
    recordid3 = t.allocate_recordid
    assert(recordid3 != recordid1)
    assert(recordid3 != recordid2)
  end

  def test_reorder_fields!
    t = Table.new %w[fruit color],
                  %w[apple red],
                  %w[banana yellow],
                  %w[orange orange]
    assert_equal(%w[_recordid fruit color], t.list_fields)
    t.reorder_fields! %w[_recordid color fruit]
    assert_equal(%w[_recordid color fruit], t.list_fields)
  end

  def test_has_field?
    t = Table.new %w[fruit color], 
                  %w[apple red], 
                  %w[banana yellow], 
                  %w[orange orange] 
    assert_equal(true, t.has_field?("fruit"))
    assert_equal(false, t.has_field?("foo"))
  end
end
