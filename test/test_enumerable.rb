require 'tb'
require 'test/unit'

class TestTbEnumerable < Test::Unit::TestCase
  def test_categorize
    a = [{:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100},
         {:fruit => "melon", :color => "green", :taste => "sweet", :price => 300},
         {:fruit => "grapefruit", :color => "yellow", :taste => "tart", :price => 200}]
    assert_equal({"yellow"=>["banana", "grapefruit"], "green"=>["melon"]},
                 a.tb_categorize(:color, :fruit))
    assert_equal({"sweet"=>["banana", "melon"], "tart"=>["grapefruit"]},
                 a.tb_categorize(:taste, :fruit))
    assert_equal({"sweet"=>{"yellow"=>["banana"], "green"=>["melon"]}, "tart"=>{"yellow"=>["grapefruit"]}},
                 a.tb_categorize(:taste, :color, :fruit))
    assert_equal({"sweet"=>["yellow", "green"], "tart"=>["yellow"]},
                 a.tb_categorize(:taste, :color))
    assert_equal({?n=>["banana", "melon"], ?e=>["grapefruit"]},
                 a.tb_categorize(lambda {|elt| elt[:fruit][4] }, :fruit))
    
    assert_equal({"yellow"=>[true, true], "green"=>[true]},
                 a.tb_categorize(:color, lambda {|e| true }))
    
    i = -1
    assert_equal({"yellow"=>[0, 2], "green"=>[1]},
                 a.tb_categorize(:color, lambda {|e| i += 1 }))
    
    assert_equal({"yellow"=>[{:fruit=>"banana", :color=>"yellow", :taste=>"sweet", :price=>100},
                             {:fruit=>"grapefruit", :color=>"yellow", :taste=>"tart", :price=>200}],
                  "green"=>[{:fruit=>"melon", :color=>"green", :taste=>"sweet", :price=>300}]},
                 a.tb_categorize(:color, lambda {|e| e }))
    
    assert_equal({"yellow"=>[{:fruit=>"banana", :color=>"yellow", :taste=>"sweet", :price=>100},
                             {:fruit=>"grapefruit", :color=>"yellow", :taste=>"tart", :price=>200}],
                  "green"=>[{:fruit=>"melon", :color=>"green", :taste=>"sweet", :price=>300}]},
                 a.tb_categorize(:color, lambda {|e| e }))
    
    i = -1
    assert_equal({"yellow"=>[["banana", "sweet", 0], ["grapefruit", "tart", 2]],
                  "green"=>[["melon", "sweet", 1]]},
                 a.tb_categorize(:color, [:fruit, :taste, lambda {|e| i += 1 }]))
    
    assert_equal({true=>["banana", "melon", "grapefruit"]},
                 a.tb_categorize(lambda {|e| true }, :fruit))
    
    assert_equal({"yellow"=>2, "green"=>1},
                 a.tb_categorize(:color, lambda {|e| true }, :seed=>0, :op=>lambda {|s, v| s+1 }))

    assert_raise(ArgumentError) { a.tb_categorize(:color, lambda {|e| true }, :seed=>0,
                                               :seed=>nil,
                                               :op=>lambda {|s, v| s+1 },
                                               :update=>lambda {|ks, s, v| s+1 }) }
    
    assert_equal({"yellow"=>"bananagrapefruit", "green"=>"melon"},
                 a.tb_categorize(:color, :fruit, :seed=>"", :op=>:+))

    assert_equal({"yellow"=>2, "green"=>1},
                 a.tb_categorize(:color, lambda {|e| 1 }, :op=>:+))
    
    assert_equal({"yellow"=>"banana,grapefruit", "green"=>"melon"},
                 a.tb_categorize(:color, :fruit) {|ks, vs| vs.join(",") } )
    
    assert_equal({"yellow"=>150.0, "green"=>300.0},
                 a.tb_categorize(:color, :price) {|ks, vs| vs.inject(0.0, &:+) / vs.length })

    assert_equal({"yellow"=>{"banana"=>100.0, "grapefruit"=>200.0}, "green"=>{"melon"=>300.0}},
                 a.tb_categorize(:color, :fruit, :price) {|ks, vs| vs.inject(0.0, &:+) / vs.length })
    
    assert_raise(ArgumentError) { a.tb_categorize('a') }
  end

  def test_categorize_proc
    c = Object.new
    def c.call(v) 10 end
    assert_equal({10=>[10]}, [[1]].tb_categorize(c, c))
    assert_raise(NoMethodError) { [[1]].tb_categorize(0, 0, :seed=>nil, :update=>c) }
    assert_raise(NoMethodError) { [[1]].tb_categorize(0, 0, :seed=>nil, :op=>c) }

    t = Object.new
    def t.to_proc() lambda {|*| 11 } end
    assert_raise(TypeError) { [[1]].tb_categorize(t, t) }
    assert_equal({1=>11}, [[1]].tb_categorize(0, 0, :seed=>nil, :update=>t))
    assert_equal({1=>11}, [[1]].tb_categorize(0, 0, :seed=>nil, :op=>t))

    ct = Object.new
    def ct.call(v) 12 end
    def ct.to_proc() lambda {|*| 13 } end
    assert_equal({12=>[12]}, [[1]].tb_categorize(ct, ct))
    assert_equal({1=>13}, [[1]].tb_categorize(0, 0, :seed=>nil, :update=>ct))
    assert_equal({1=>13}, [[1]].tb_categorize(0, 0, :seed=>nil, :op=>ct))
  end

  def test_unique_categorize
    a = [{:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100},
         {:fruit => "melon", :color => "green", :taste => "sweet", :price => 300},
         {:fruit => "grapefruit", :color => "yellow", :taste => "tart", :price => 200}]
    assert_equal({"banana"=>100, "melon"=>300, "grapefruit"=>200},
                 a.tb_unique_categorize(:fruit, :price))
  
    assert_raise(ArgumentError) { a.tb_unique_categorize(:color, :price) }
  
    assert_equal({"sweet"=>400, "tart"=>200},
                 a.tb_unique_categorize(:taste, :price) {|s, v| !s ? v : s + v })
  
    assert_equal({"yellow"=>300, "green"=>300},
                 a.tb_unique_categorize(:color, :price, :seed=>0) {|s, v| s + v })
  end

  def test_category_count
    a = [{:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100},
         {:fruit => "melon", :color => "green", :taste => "sweet", :price => 300},
         {:fruit => "grapefruit", :color => "yellow", :taste => "tart", :price => 200}]
  
    assert_equal({"yellow"=>2, "green"=>1},
                 a.tb_category_count(:color))
  
    assert_equal({"sweet"=>2, "tart"=>1},
                 a.tb_category_count(:taste))
  
    assert_equal({"sweet"=>{"yellow"=>1, "green"=>1}, "tart"=>{"yellow"=>1}},
                 a.tb_category_count(:taste, :color))
  end

  def test_extsort_by_empty
    assert_equal([], [].extsort_by {|x| x }.to_a)
  end

  def test_extsort_by_exhaustive
    #maxlen = 7
    maxlen = 3
    (maxlen+1).times {|len|
      (len**len).times {|i|
        ary = []
        len.times {|j|
          ary << (i % len)
          i /= len
        }
        uary = ary.sort.uniq
        next if uary[0] != 0 || uary[-1] != uary.length - 1
        ary1 = ary.map.with_index.to_a
        #p ary1
        ary2 = ary1.extsort_by {|v, k| v }.to_a
        assert_equal(ary1.sort, ary2,
                     "#{ary.inspect}.extsort_by {|v, k| v }.to_a")
      }
    }
  end

  def test_extsort_by_random
    10.times {|i|
      len = rand(100)
      ary = []
      len.times { ary << rand(1000) }
      ary1 = ary.sort
      ary2 = ary.extsort_by {|x| x }.to_a
      assert_equal(ary1, ary2)
    }
  end

  def test_extsort_by_block_random
    3.times {|i|
      len = rand(100)
      ary = []
      len.times { ary << rand(1000) }
      ary1 = ary.sort.reverse
      ary2 = ary.extsort_by {|x| -x }.to_a
      assert_equal(ary1, ary2)
    }
  end

end
