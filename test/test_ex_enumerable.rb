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
    maxlen = 3
    #maxlen = 7
    midsize = Marshal.dump([0,0]).size + 1
    [0, midsize, nil].each {|memsize|
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
          #p [memsize, ary1]
          ary2 = ary1.extsort_by(:memsize => memsize) {|v, k| v }.to_a
          assert_equal(ary1.sort, ary2,
                       "#{ary.inspect}.extsort_by(:memsize=>#{memsize}) {|v, k| v }.to_a")
        }
      }
    }
  end

  def test_extsort_by_random
    midsize = Marshal.dump([0,0]).size + 1
    [0, midsize, nil].each {|memsize|
      10.times {|i|
        len = rand(100)
        ary = []
        len.times { ary << rand(1000) }
        ary1 = ary.sort
        ary2 = ary.extsort_by(:memsize => memsize) {|x| x }.to_a
        assert_equal(ary1, ary2)
      }
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

  def test_extsort_by_map
    assert_equal([20,12,13],
      [10,2,3].extsort_by(:map => lambda {|v| v + 10 }) {|v| v.to_s }.to_a)
  end

  def test_extsort_by_unique
    [
      [[1,1], [2]],
      [[1,2,1], [2,2]],
      [[1,2,3,2,1], [2,4,3]],
      [[1,1,2,2,3], [2,4,3]]
    ].each {|ary, result|
      [nil, 0].each {|memsize|
        assert_equal(result,
          ary.extsort_by(:memsize => memsize,
                         :unique => lambda {|x,y| x + y }) {|x| x }.to_a)
      }
    }
  end

  def test_extsort_by_unique_random
    [nil, 0].each {|memsize|
      3.times {|i|
        len = rand(100)
        ary = []
        len.times { ary << rand(100) }
        h = ary.group_by {|v| v }
        ary1 = h.keys.sort.map {|k| h[k].inject(&:+) }
        ary2 = ary.extsort_by(:memsize => memsize,
                              :unique => lambda {|x, y| x + y }) {|v| v }.to_a
        assert_equal(ary1, ary2)
      }
    }
  end

  def test_extsort_reduce
    result = [
      [:cat, 1],
      [:dog, 2],
      [:cat, 3],
      [:dog, 1],
    ].extsort_reduce(:+.to_proc) {|pair| pair }.to_a
    assert_equal([[:cat, 4], [:dog, 3]], result)
  end

  def test_each_group_element
    result = []
    (0..9).to_a.each_group_element(
      lambda {|a, b| a / 3 != b / 3 },
      lambda {|v| result << [:before, v] },
      lambda {|v| result << [:body, v] },
      lambda {|v| result << [:after, v] })
    assert_equal(
      [[:before, 0],
       [:body, 0],
       [:body, 1],
       [:body, 2],
       [:after, 2],
       [:before, 3],
       [:body, 3],
       [:body, 4],
       [:body, 5],
       [:after, 5],
       [:before, 6],
       [:body, 6],
       [:body, 7],
       [:body, 8],
       [:after, 8],
       [:before, 9],
       [:body, 9],
       [:after, 9]],
      result)
  end

  def test_each_group_element_by
    result = []
    (0..9).to_a.each_group_element_by(
      lambda {|v| v / 3 },
      lambda {|v| result << [:before, v] },
      lambda {|v| result << [:body, v] },
      lambda {|v| result << [:after, v] })
    assert_equal(
      [[:before, 0],
       [:body, 0],
       [:body, 1],
       [:body, 2],
       [:after, 2],
       [:before, 3],
       [:body, 3],
       [:body, 4],
       [:body, 5],
       [:after, 5],
       [:before, 6],
       [:body, 6],
       [:body, 7],
       [:body, 8],
       [:after, 8],
       [:before, 9],
       [:body, 9],
       [:after, 9]],
      result)
  end

  def test_detect_group_by
    enum = (0..9).to_a
    result = []
    e3 = enum.detect_group_by(
      lambda {|elt| result << [:before, 3, elt] },
      lambda {|elt| result << [:after, 3, elt] }) {|elt|
      elt / 3
    }
    e4 = e3.detect_group_by(
      lambda {|elt| result << [:before, 4, elt] },
      lambda {|elt| result << [:after, 4, elt] }) {|elt|
      elt / 4
    }
    e4.each {|elt|
      result << [:body, elt]
    }
    assert_equal(
      [[:before, 3, 0],
       [:before, 4, 0],
       [:body, 0],
       [:body, 1],
       [:body, 2],
       [:after, 3, 2],
       [:before, 3, 3],
       [:body, 3],
       [:after, 4, 3],
       [:before, 4, 4],
       [:body, 4],
       [:body, 5],
       [:after, 3, 5],
       [:before, 3, 6],
       [:body, 6],
       [:body, 7],
       [:after, 4, 7],
       [:before, 4, 8],
       [:body, 8],
       [:after, 3, 8],
       [:before, 3, 9],
       [:body, 9],
       [:after, 3, 9],
       [:after, 4, 9]],
      result)
  end

  def test_detect_nested_group_by_simple
    assert_equal([], [].detect_nested_group_by([]).to_a)
    assert_equal([1], [1].detect_nested_group_by([]).to_a)

    result = []
    [].detect_nested_group_by(
      [[lambda {|v| v.even? },
        lambda {|v| result << [:s, v] },
        lambda {|v| result << [:e, v] }]]).each {|v| result << v } 
    assert_equal([], result)
  end

  def test_detect_nested_group_by
    enum = (0..9).to_a
    result = []
    e = enum.detect_nested_group_by(
     [[lambda {|elt| elt / 3 },
       lambda {|elt| result << [:before, 3, elt] },
       lambda {|elt| result << [:after, 3, elt] }],
      [lambda {|elt| elt / 4 },
       lambda {|elt| result << [:before, 4, elt] },
       lambda {|elt| result << [:after, 4, elt] }]])
    e.each {|elt|
      result << [:body, elt]
    }
    assert_equal(
      [[:before, 3, 0],
       [:before, 4, 0],
       [:body, 0],
       [:body, 1],
       [:body, 2],
       [:after, 4, 2],
       [:after, 3, 2],
       [:before, 3, 3],
       [:before, 4, 3],
       [:body, 3],
       [:after, 4, 3],
       [:before, 4, 4],
       [:body, 4],
       [:body, 5],
       [:after, 4, 5],
       [:after, 3, 5],
       [:before, 3, 6],
       [:before, 4, 6],
       [:body, 6],
       [:body, 7],
       [:after, 4, 7],
       [:before, 4, 8],
       [:body, 8],
       [:after, 4, 8],
       [:after, 3, 8],
       [:before, 3, 9],
       [:before, 4, 9],
       [:body, 9],
       [:after, 4, 9],
       [:after, 3, 9]],
      result)
  end

end
