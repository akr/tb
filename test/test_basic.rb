require 'table'
require 'test/unit'

class TestTableBasic < Test::Unit::TestCase
  def test_initialize
    t = Table.new
    assert_equal([], t.list_fields)
    t = Table.new %w[fruit color],
                  %w[apple red],
                  %w[banana yellow],
                  %w[orange orange]
    assert_equal(%w[fruit color].sort, t.list_fields.sort)
    a = t.to_a.map {|r| r.to_h_with_reserved }
    assert_operator(a, :include?, {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"})
    assert_operator(a, :include?, {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"})
    assert_operator(a, :include?, {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"})
    assert_equal(3, a.length)
  end

  def test_enumerable
    t = Table.new
    assert_kind_of(Enumerable, t)
  end

  def test_define_field
    t = Table.new %w[fruit color],
                  %w[apple red],
                  %w[banana yellow],
                  %w[orange orange]
    t.define_field("namelen") {|record| record["fruit"].length }
    t.each {|rec|
      case rec['fruit']
      when 'apple' then assert_equal(5, rec['namelen'])
      when 'banana' then assert_equal(6, rec['namelen'])
      when 'orange' then assert_equal(6, rec['namelen'])
      else raise
      end
    }
  end

  def test_list_fields
    t = Table.new
    assert_equal([], t.list_fields)
    assert_equal([], t.list_fields)
    assert_equal(["_recordid"], t.list_fields_all)
    t = Table.new %w[fruit color],
                  %w[apple red],
                  %w[banana yellow],
                  %w[orange orange]
    assert_equal(%w[fruit color], t.list_fields)
    assert_equal(%w[fruit color], t.list_fields)
    assert_equal(%w[_recordid fruit color], t.list_fields_all)
  end

  def test_list_recordids
    t = Table.new
    assert_equal([], t.list_recordids)
    recordid1 = t.allocate_recordid
    assert_equal([recordid1], t.list_recordids)
    recordid2 = t.allocate_recordid
    assert_equal([recordid1, recordid2], t.list_recordids)
    assert_equal(nil, t.delete_recordid(recordid1))
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
    t.delete_recordid(recordid)
    assert_raise(IndexError) { t.get_cell(recordid, :g) }
    assert_raise(IndexError) { t.get_cell(100, :g) }
    assert_raise(IndexError) { t.get_cell(-1, :g) }
    assert_raise(TypeError) { t.get_cell(:invalid_recordid, :g) }
  end

  def test_each_field
    t = Table.new %w[a b z]
    a = []
    t.each_field_with_reserved {|f| a << f }
    assert_equal(%w[_recordid a b z], a)
    a = []
    t.each_field {|f| a << f }
    assert_equal(%w[a b z], a)
  end

  def test_each_record
    t = Table.new %w[a], [1], [2]
    records = []
    t.each {|record| records << record.to_h_with_reserved }
    assert_equal([{"_recordid"=>0, "a"=>1}, {"_recordid"=>1, "a"=>2}], records)
  end

  def test_categorize
    t = Table.new %w[a b c], [1,2,3], [2,4,3]
    assert_raise(ArgumentError) { t.categorize('a') }
    assert_equal({1=>[2], 2=>[4]}, t.categorize('a', 'b'))
    assert_equal({1=>{2=>[3]}, 2=>{4=>[3]}}, t.categorize('a', 'b', 'c'))
    assert_equal({1=>[[2,3]], 2=>[[4,3]]}, t.categorize('a', ['b', 'c']))
    assert_equal({[1,2]=>[3], [2,4]=>[3]}, t.categorize(['a', 'b'], 'c'))
    assert_equal({3=>[2,4]}, t.categorize('c', 'b'))
    assert_equal({3=>[true,true]}, t.categorize('c', lambda {|e| true }))
    assert_equal({3=>2}, t.categorize('c', 'b') {|ks, vs| vs.length } )
    assert_equal({3=>2}, t.categorize('c', 'b',
                                      :seed=>0,
                                      :update=> lambda {|ks, s, v| s + 1 }))
    assert_equal({true => [1,2]}, t.categorize(lambda {|e| true }, 'a'))
    h = t.categorize('a', lambda {|e| e })
    assert_equal(2, h.size)
    assert_equal([1, 2], h.keys.sort)
    assert_instance_of(Array, h[1])
    assert_instance_of(Array, h[2])
    assert_equal(1, h[1].length)
    assert_equal(1, h[2].length)
    assert_instance_of(Table::Record, h[1][0])
    assert_instance_of(Table::Record, h[2][0])
    assert_same(t, h[1][0].table)
    assert_same(t, h[2][0].table)
    assert_equal(0, h[1][0].record_id)
    assert_equal(1, h[2][0].record_id)
    assert_same(t, h[2][0].table)

    assert_raise(ArgumentError) { t.categorize(:_foo, lambda {|e| true }) }
    assert_equal({3=>[2], 6=>[4]}, t.categorize(lambda {|rec| rec['a'] * 3 }, 'b'))
    assert_equal({[1,2]=>[[2,3]], [2,4]=>[[4,3]]}, t.categorize(['a', 'b'], ['b', 'c']))
    assert_equal({1=>2, 2=>4}, t.categorize('a', 'b', :seed=>0, :op=>:+))
    assert_raise(ArgumentError) { t.categorize('a', 'b', :op=>:+, :update=>lambda {|ks, s, v| v }) }
    i = -1
    assert_equal({3=>[0, 1]}, t.categorize('c', lambda {|e| i += 1 }))
  end

  def test_unique_categorize
    t = Table.new %w[a b c], [1,2,3], [2,4,4]
    assert_equal({1=>3, 2=>4}, t.unique_categorize("a", "c"))
    assert_equal({1=>[3], 2=>[4]}, t.unique_categorize("a", "c", :seed=>nil) {|seed, v| !seed ? [v] : (seed << v) })
    assert_equal({1=>1, 2=>1}, t.unique_categorize("a", "c", :seed=>nil) {|seed, v| !seed ? 1 : seed + 1 })
    assert_equal({1=>{2=>3}, 2=>{4=>4}}, t.unique_categorize("a", "b", "c"))
    t.insert({"a"=>2, "b"=>7, "c"=>8})
    assert_equal({1=>{2=>3}, 2=>{4=>4, 7=>8}}, t.unique_categorize("a", "b", "c"))
  end

  def test_unique_categorize_ambiguous
    t = Table.new %w[a b c], [1,2,3], [1,4,4]
    assert_raise(ArgumentError) { t.unique_categorize("a", "c") }
    assert_equal({1=>[3,4]}, t.unique_categorize("a", "c", :seed=>nil) {|seed, v| !seed ? [v] : (seed << v) })
    assert_equal({1=>2}, t.unique_categorize("a", "c", :seed=>nil) {|seed, v| !seed ? 1 : seed + 1 })
  end

  def test_category_count
    t = Table.new %w[a b c], [1,2,3], [2,4,3]
    assert_equal({1=>1, 2=>1}, t.category_count("a"))
    assert_equal({2=>1, 4=>1}, t.category_count("b"))
    assert_equal({3=>2}, t.category_count("c"))
    assert_equal({3=>{1=>1, 2=>1}}, t.category_count("c", "a"))
  end

  def test_natjoin2
    t1 = Table.new %w[a b], %w[1 2], %w[3 4], %w[0 4]
    t2 = Table.new %w[b c], %w[2 3], %w[4 5]
    t3 = t1.natjoin2(t2)
    assert_equal([{"_recordid"=>0, "a"=>"1", "b"=>"2", "c"=>"3"},
                  {"_recordid"=>1, "a"=>"3", "b"=>"4", "c"=>"5"},
                  {"_recordid"=>2, "a"=>"0", "b"=>"4", "c"=>"5"}], t3.to_a.map {|r| r.to_h_with_reserved })
  end

  def test_fmap!
    t = Table.new %w[a b], %w[1 2], %w[3 4]
    t.fmap!("a") {|recordid, v| "foo" + v }
    assert_equal([{"_recordid"=>0, "a"=>"foo1", "b"=>"2"},
                  {"_recordid"=>1, "a"=>"foo3", "b"=>"4"}], t.to_a.map {|r| r.to_h_with_reserved })
  end

  def test_delete_field
    t = Table.new(%w[a b], %w[1 2], %w[3 4])
    t.delete_field("a")
    assert_equal([{"_recordid"=>0, "b"=>"2"},
                  {"_recordid"=>1, "b"=>"4"}], t.to_a.map {|r| r.to_h_with_reserved })
  end

  def test_delete_recordid
    t = Table.new %w[a]
    recordid = t.insert({"a"=>"foo"})
    t.insert({"a"=>"bar"})
    t.delete_recordid(recordid)
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
    assert_equal([{"_recordid"=>0, "a"=>1, "b"=>2}], t1.to_a.map {|r| r.to_h_with_reserved })
    t2 = t1.rename_field("a" => "c", "b" => "d")
    assert_equal([{"_recordid"=>0, "a"=>1, "b"=>2}], t1.to_a.map {|r| r.to_h_with_reserved })
    assert_equal([{"_recordid"=>0, "c"=>1, "d"=>2}], t2.to_a.map {|r| r.to_h_with_reserved })
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
    assert_equal(%w[fruit color], t.list_fields)
    t.reorder_fields! %w[color fruit]
    assert_equal(%w[_recordid color fruit], t.list_fields_all)
    t.reorder_fields! %w[fruit _recordid color]
    assert_equal(%w[fruit _recordid color], t.list_fields_all)
  end

  def test_has_field?
    t = Table.new %w[fruit color], 
                  %w[apple red], 
                  %w[banana yellow], 
                  %w[orange orange] 
    assert_equal(true, t.has_field?("fruit"))
    assert_equal(false, t.has_field?("foo"))
  end

  def test_filter
    t = Table.new %w[fruit color],
                  %w[apple red],
                  %w[banana yellow],
                  %w[orange orange]
    t2 = t.filter {|rec| rec["fruit"] == "banana" }
    assert_equal(1, t2.size)
  end
end
