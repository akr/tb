require 'tb'
require 'test/unit'

class TestTbBasic < Test::Unit::TestCase
  def test_initialize
    t = Tb.new
    assert_equal([], t.list_fields)
    t = Tb.new %w[fruit color],
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

  def test_replace
    t1 = Tb.new %w[fruit color],
                %w[apple red],
                %w[banana yellow],
                %w[orange orange]
    t2 = Tb.new %w[grain color],
                %w[rice white],
                %w[wheat light-brown]
    t1.replace t2
    assert_equal([{"grain"=>"rice", "color"=>"white"},
                  {"grain"=>"wheat", "color"=>"light-brown"}],
                 t2.to_a.map {|rec| rec.to_h })
  end

  def test_pretty_print
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    s = t.pretty_inspect
    assert_match(/fruit/, s)
    assert_match(/color/, s)
    assert_match(/apple/, s)
    assert_match(/red/, s)
    assert_match(/banana/, s)
    assert_match(/yellow/, s)
    assert_match(/orange/, s)
  end

  def test_enumerable
    t = Tb.new
    assert_kind_of(Enumerable, t)
  end

  def test_define_field
    t = Tb.new %w[fruit color],
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

  def test_define_field_error
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    assert_raise(ArgumentError) { t.define_field("_foo") }
    assert_raise(ArgumentError) { t.define_field("fruit") }
  end

  def test_list_fields
    t = Tb.new
    assert_equal([], t.list_fields)
    assert_equal([], t.list_fields)
    assert_equal(["_recordid"], t.list_fields_all)
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    assert_equal(%w[fruit color], t.list_fields)
    assert_equal(%w[fruit color], t.list_fields)
    assert_equal(%w[_recordid fruit color], t.list_fields_all)
  end

  def test_list_recordids
    t = Tb.new
    assert_equal([], t.list_recordids)
    recordid1 = t.allocate_recordid
    assert_equal([recordid1], t.list_recordids)
    recordid2 = t.allocate_recordid
    assert_equal([recordid1, recordid2], t.list_recordids)
    assert_equal(nil, t.delete_recordid(recordid1))
    assert_equal([recordid2], t.list_recordids)
  end

  def test_cell
    t = Tb.new %w[f g]
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
    t = Tb.new %w[a b z]
    a = []
    t.each_field_with_reserved {|f| a << f }
    assert_equal(%w[_recordid a b z], a)
    a = []
    t.each_field {|f| a << f }
    assert_equal(%w[a b z], a)
  end

  def test_each_record
    t = Tb.new %w[a], [1], [2]
    records = []
    t.each {|record| records << record.to_h_with_reserved }
    assert_equal([{"_recordid"=>0, "a"=>1}, {"_recordid"=>1, "a"=>2}], records)
  end

  def test_categorize
    t = Tb.new %w[a b c], [1,2,3], [2,4,3]
    assert_raise(ArgumentError) { t.tb_categorize('a') }
    assert_equal({1=>[2], 2=>[4]}, t.tb_categorize('a', 'b'))
    assert_equal({1=>{2=>[3]}, 2=>{4=>[3]}}, t.tb_categorize('a', 'b', 'c'))
    assert_equal({1=>[[2,3]], 2=>[[4,3]]}, t.tb_categorize('a', ['b', 'c']))
    assert_equal({[1,2]=>[3], [2,4]=>[3]}, t.tb_categorize(['a', 'b'], 'c'))
    assert_equal({3=>[2,4]}, t.tb_categorize('c', 'b'))
    assert_equal({3=>[true,true]}, t.tb_categorize('c', lambda {|e| true }))
    assert_equal({3=>2}, t.tb_categorize('c', 'b') {|ks, vs| vs.length } )
    assert_equal({3=>2}, t.tb_categorize('c', 'b',
                                      :seed=>0,
                                      :update=> lambda {|ks, s, v| s + 1 }))
    assert_equal({true => [1,2]}, t.tb_categorize(lambda {|e| true }, 'a'))
    h = t.tb_categorize('a', lambda {|e| e })
    assert_equal(2, h.size)
    assert_equal([1, 2], h.keys.sort)
    assert_instance_of(Array, h[1])
    assert_instance_of(Array, h[2])
    assert_equal(1, h[1].length)
    assert_equal(1, h[2].length)
    assert_instance_of(Tb::Record, h[1][0])
    assert_instance_of(Tb::Record, h[2][0])
    assert_same(t, h[1][0].table)
    assert_same(t, h[2][0].table)
    assert_equal(0, h[1][0].record_id)
    assert_equal(1, h[2][0].record_id)
    assert_same(t, h[2][0].table)

    assert_raise(ArgumentError) { t.tb_categorize(:_foo, lambda {|e| true }) }
    assert_equal({3=>[2], 6=>[4]}, t.tb_categorize(lambda {|rec| rec['a'] * 3 }, 'b'))
    assert_equal({[1,2]=>[[2,3]], [2,4]=>[[4,3]]}, t.tb_categorize(['a', 'b'], ['b', 'c']))
    assert_equal({1=>2, 2=>4}, t.tb_categorize('a', 'b', :seed=>0, :op=>:+))
    assert_raise(ArgumentError) { t.tb_categorize('a', 'b', :op=>:+, :update=>lambda {|ks, s, v| v }) }
    i = -1
    assert_equal({3=>[0, 1]}, t.tb_categorize('c', lambda {|e| i += 1 }))
  end

  def test_unique_categorize
    t = Tb.new %w[a b c], [1,2,3], [2,4,4]
    assert_equal({1=>3, 2=>4}, t.tb_unique_categorize("a", "c"))
    assert_equal({1=>[3], 2=>[4]}, t.tb_unique_categorize("a", "c", :seed=>nil) {|seed, v| !seed ? [v] : (seed << v) })
    assert_equal({1=>1, 2=>1}, t.tb_unique_categorize("a", "c", :seed=>nil) {|seed, v| !seed ? 1 : seed + 1 })
    assert_equal({1=>{2=>3}, 2=>{4=>4}}, t.tb_unique_categorize("a", "b", "c"))
    t.insert({"a"=>2, "b"=>7, "c"=>8})
    assert_equal({1=>{2=>3}, 2=>{4=>4, 7=>8}}, t.tb_unique_categorize("a", "b", "c"))
  end

  def test_unique_categorize_ambiguous
    t = Tb.new %w[a b c], [1,2,3], [1,4,4]
    assert_raise(ArgumentError) { t.tb_unique_categorize("a", "c") }
    assert_equal({1=>[3,4]}, t.tb_unique_categorize("a", "c", :seed=>nil) {|seed, v| !seed ? [v] : (seed << v) })
    assert_equal({1=>2}, t.tb_unique_categorize("a", "c", :seed=>nil) {|seed, v| !seed ? 1 : seed + 1 })
  end

  def test_category_count
    t = Tb.new %w[a b c], [1,2,3], [2,4,3]
    assert_equal({1=>1, 2=>1}, t.tb_category_count("a"))
    assert_equal({2=>1, 4=>1}, t.tb_category_count("b"))
    assert_equal({3=>2}, t.tb_category_count("c"))
    assert_equal({3=>{1=>1, 2=>1}}, t.tb_category_count("c", "a"))
  end

  def test_natjoin2
    t1 = Tb.new %w[a b], %w[1 2], %w[3 4], %w[0 4]
    t2 = Tb.new %w[b c], %w[2 3], %w[4 5], %w[5 8]
    t3 = t1.natjoin2(t2)
    assert_equal([{"a"=>"1", "b"=>"2", "c"=>"3"},
                  {"a"=>"3", "b"=>"4", "c"=>"5"},
                  {"a"=>"0", "b"=>"4", "c"=>"5"}],
                 t3.to_a.map {|r| r.to_h })
  end

  def test_natjoin2_nocommon
    t1 = Tb.new %w[a b], %w[1 2], %w[3 4]
    t2 = Tb.new %w[c d], %w[5 6], %w[7 8]
    t3 = t1.natjoin2(t2)
    assert_equal([{"a"=>"1", "b"=>"2", "c"=>"5", "d"=>"6"},
                  {"a"=>"1", "b"=>"2", "c"=>"7", "d"=>"8"},
                  {"a"=>"3", "b"=>"4", "c"=>"5", "d"=>"6"},
                  {"a"=>"3", "b"=>"4", "c"=>"7", "d"=>"8"}],
                  t3.to_a.map {|r| r.to_h })
  end

  def test_natjoin2_outer
    t1 = Tb.new %w[a b], %w[1 2], %w[3 4], %w[0 4], %w[0 1]
    t2 = Tb.new %w[b c], %w[2 3], %w[4 5], %w[5 8]
    t3 = t1.natjoin2_outer(t2)
    assert_equal([{"a"=>"0", "b"=>"1"},
                  {"a"=>"1", "b"=>"2", "c"=>"3"},
                  {"a"=>"3", "b"=>"4", "c"=>"5"},
                  {"a"=>"0", "b"=>"4", "c"=>"5"},
                  {"b"=>"5", "c"=>"8"}],
                 t3.to_a.map {|r| r.to_h })
  end

  def test_fmap!
    t = Tb.new %w[a b], %w[1 2], %w[3 4]
    t.fmap!("a") {|record, v| "foo" + v }
    assert_equal([{"_recordid"=>0, "a"=>"foo1", "b"=>"2"},
                  {"_recordid"=>1, "a"=>"foo3", "b"=>"4"}], t.to_a.map {|r| r.to_h_with_reserved })
  end

  def test_delete_field
    t = Tb.new(%w[a b], %w[1 2], %w[3 4])
    t.delete_field("a")
    assert_equal([{"_recordid"=>0, "b"=>"2"},
                  {"_recordid"=>1, "b"=>"4"}], t.to_a.map {|r| r.to_h_with_reserved })
  end

  def test_delete_recordid
    t = Tb.new %w[a]
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
    t1 = Tb.new %w[a b], [1, 2]
    assert_equal([{"_recordid"=>0, "a"=>1, "b"=>2}], t1.to_a.map {|r| r.to_h_with_reserved })
    t2 = t1.rename_field("a" => "c", "b" => "d")
    assert_equal([{"_recordid"=>0, "a"=>1, "b"=>2}], t1.to_a.map {|r| r.to_h_with_reserved })
    assert_equal([{"_recordid"=>0, "c"=>1, "d"=>2}], t2.to_a.map {|r| r.to_h_with_reserved })
  end

  def test_allocate_recordid
    t = Tb.new
    recordid1 = t.allocate_recordid(100)
    assert_equal(100, recordid1)
    recordid2 = t.allocate_recordid(200)
    assert_equal(200, recordid2)
    recordid3 = t.allocate_recordid
    assert(recordid3 != recordid1)
    assert(recordid3 != recordid2)
  end

  def test_allocate_recordid_error
    t = Tb.new
    recordid1 = t.allocate_recordid
    assert_raise(ArgumentError) { t.allocate_recordid(recordid1) }
  end

  def test_allocate_record
    t = Tb.new
    rec1 = t.allocate_record
    assert_kind_of(Tb::Record, rec1)
    rec2 = t.allocate_record(200)
    assert_kind_of(Tb::Record, rec2)
    assert_equal(200, rec2.record_id)
  end

  def test_reorder_fields!
    t = Tb.new %w[fruit color],
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
    t = Tb.new %w[fruit color], 
               %w[apple red], 
               %w[banana yellow], 
               %w[orange orange] 
    assert_equal(true, t.has_field?("fruit"))
    assert_equal(false, t.has_field?("foo"))
  end

  def test_filter
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    t2 = t.filter {|rec| rec["fruit"] == "banana" }
    assert_equal(1, t2.size)
  end

  def test_reorder_records_by
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    t2 = t.reorder_records_by {|rec| rec["color"] }
    assert_equal(t.map {|rec| rec["color"] }.sort, t2.map {|rec| rec["color"] })
  end

  def test_insert_values
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    res = t.insert_values(["fruit", "color"], ["grape", "purple"], ["cherry", "red"])
    assert_equal([3, 4], res)
    assert_equal(["grape", "purple"], t.get_values(3, "fruit", "color"))
    assert_equal(["cherry", "red"], t.get_values(4, "fruit", "color"))
  end

  def test_insert_values_error
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    assert_raise(ArgumentError) { t.insert_values(["fruit", "color"], ["grape", "purple", "red"]) }
  end

  def test_concat
    t1 = Tb.new %w[fruit color],
                %w[apple red]
    t2 = Tb.new %w[fruit color],
                %w[banana yellow],
                %w[orange orange]
    t3 = t1.concat(t2)
    assert_same(t1, t3)
    assert_equal(3, t1.size)
    assert_equal(["banana", "yellow"], t1.get_values(1, "fruit", "color"))
    assert_equal(["orange", "orange"], t1.get_values(2, "fruit", "color"))
  end

  def test_each_record_values
    t = Tb.new %w[fruit color],
               %w[banana yellow],
               %w[orange orange]
    rs = []
    t.each_record_values('fruit') {|r| rs << r }
    assert_equal([['banana'], ['orange']], rs)
    rs = []
    t.each_record_values('fruit', 'color') {|r| rs << r }
    assert_equal([['banana', 'yellow'], ['orange', 'orange']], rs)
  end

  def test_with_header
    t = Tb.new %w[a b], [1, 2], [3, 4]
    result = []
    t.with_header {|x|
      result << x
    }.each {|x|
      result << x
    }
    assert_equal(3, result.length)
    assert_equal(%w[a b], result[0])
    assert_kind_of(Tb::Record, result[1])
    assert_kind_of(Tb::Record, result[2])
    assert_equal([["a", 1], ["b", 2]], result[1].to_a)
    assert_equal([["a", 3], ["b", 4]], result[2].to_a)
  end

end
