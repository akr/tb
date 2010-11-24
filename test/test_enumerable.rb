require 'table/enumerable'
require 'test/unit'

class TestTableEnumerable < Test::Unit::TestCase
  def test_categorize
    a = [{:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100},
         {:fruit => "melon", :color => "green", :taste => "sweet", :price => 300},
         {:fruit => "grapefruit", :color => "yellow", :taste => "tart", :price => 200}]
    assert_equal({"yellow"=>["banana", "grapefruit"], "green"=>["melon"]},
                 a.categorize(:color, :fruit))
    assert_equal({"sweet"=>["banana", "melon"], "tart"=>["grapefruit"]},
                 a.categorize(:taste, :fruit))
    assert_equal({"sweet"=>{"yellow"=>["banana"], "green"=>["melon"]}, "tart"=>{"yellow"=>["grapefruit"]}},
                 a.categorize(:taste, :color, :fruit))
    assert_equal({"sweet"=>["yellow", "green"], "tart"=>["yellow"]},
                 a.categorize(:taste, :color))
    assert_equal({?n=>["banana", "melon"], ?e=>["grapefruit"]},
                 a.categorize(lambda {|elt| elt[:fruit][4] }, :fruit))
    
    assert_equal({"yellow"=>[true, true], "green"=>[true]},
                 a.categorize(:color, lambda {|e| true }))
    
    i = -1
    assert_equal({"yellow"=>[0, 2], "green"=>[1]},
                 a.categorize(:color, lambda {|e| i += 1 }))
    
    assert_equal({"yellow"=>[{:fruit=>"banana", :color=>"yellow", :taste=>"sweet", :price=>100},
                             {:fruit=>"grapefruit", :color=>"yellow", :taste=>"tart", :price=>200}],
                  "green"=>[{:fruit=>"melon", :color=>"green", :taste=>"sweet", :price=>300}]},
                 a.categorize(:color, lambda {|e| e }))
    
    assert_equal({"yellow"=>[{:fruit=>"banana", :color=>"yellow", :taste=>"sweet", :price=>100},
                             {:fruit=>"grapefruit", :color=>"yellow", :taste=>"tart", :price=>200}],
                  "green"=>[{:fruit=>"melon", :color=>"green", :taste=>"sweet", :price=>300}]},
                 a.categorize(:color, lambda {|e| e }))
    
    i = -1
    assert_equal({"yellow"=>[["banana", "sweet", 0], ["grapefruit", "tart", 2]],
                  "green"=>[["melon", "sweet", 1]]},
                 a.categorize(:color, [:fruit, :taste, lambda {|e| i += 1 }]))
    
    assert_equal({true=>["banana", "melon", "grapefruit"]},
                 a.categorize(lambda {|e| true }, :fruit))
    
    assert_equal({"yellow"=>2, "green"=>1},
                 a.categorize(:color, lambda {|e| true }, :seed=>0, :op=>lambda {|s, v| s+1 }))

    assert_raise(ArgumentError) { a.categorize(:color, lambda {|e| true }, :seed=>0,
                                               :seed=>nil,
                                               :op=>lambda {|s, v| s+1 },
                                               :update=>lambda {|ks, s, v| s+1 }) }
    
    assert_equal({"yellow"=>"bananagrapefruit", "green"=>"melon"},
                 a.categorize(:color, :fruit, :seed=>"", :op=>:+))

    assert_equal({"yellow"=>2, "green"=>1},
                 a.categorize(:color, lambda {|e| 1 }, :op=>:+))
    
    assert_equal({"yellow"=>"banana,grapefruit", "green"=>"melon"},
                 a.categorize(:color, :fruit) {|ks, vs| vs.join(",") } )
    
    assert_equal({"yellow"=>150.0, "green"=>300.0},
                 a.categorize(:color, :price) {|ks, vs| vs.inject(0.0, &:+) / vs.length })

    assert_equal({"yellow"=>{"banana"=>100.0, "grapefruit"=>200.0}, "green"=>{"melon"=>300.0}},
                 a.categorize(:color, :fruit, :price) {|ks, vs| vs.inject(0.0, &:+) / vs.length })
    
    assert_raise(ArgumentError) { a.categorize('a') }
  end

  def test_categorize_proc
    c = Object.new
    def c.call(v) 10 end
    assert_equal({10=>[10]}, [[1]].categorize(c, c))
    assert_raise(NoMethodError) { [[1]].categorize(0, 0, :seed=>nil, :update=>c) }
    assert_raise(NoMethodError) { [[1]].categorize(0, 0, :seed=>nil, :op=>c) }

    t = Object.new
    def t.to_proc() lambda {|*| 11 } end
    assert_raise(TypeError) { [[1]].categorize(t, t) }
    assert_equal({1=>11}, [[1]].categorize(0, 0, :seed=>nil, :update=>t))
    assert_equal({1=>11}, [[1]].categorize(0, 0, :seed=>nil, :op=>t))

    ct = Object.new
    def ct.call(v) 12 end
    def ct.to_proc() lambda {|*| 13 } end
    assert_equal({12=>[12]}, [[1]].categorize(ct, ct))
    assert_equal({1=>13}, [[1]].categorize(0, 0, :seed=>nil, :update=>ct))
    assert_equal({1=>13}, [[1]].categorize(0, 0, :seed=>nil, :op=>ct))
  end

  def test_unique_categorize
    a = [{:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100},
         {:fruit => "melon", :color => "green", :taste => "sweet", :price => 300},
         {:fruit => "grapefruit", :color => "yellow", :taste => "tart", :price => 200}]
    assert_equal({"banana"=>100, "melon"=>300, "grapefruit"=>200},
                 a.unique_categorize(:fruit, :price))
  
    assert_raise(ArgumentError) { a.unique_categorize(:color, :price) }
  
    assert_equal({"sweet"=>400, "tart"=>200},
                 a.unique_categorize(:taste, :price) {|s, v| !s ? v : s + v })
  
    assert_equal({"yellow"=>300, "green"=>300},
                 a.unique_categorize(:color, :price, :seed=>0) {|s, v| s + v })
  end

  def test_category_count
    a = [{:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100},
         {:fruit => "melon", :color => "green", :taste => "sweet", :price => 300},
         {:fruit => "grapefruit", :color => "yellow", :taste => "tart", :price => 200}]
  
    assert_equal({"yellow"=>2, "green"=>1},
                 a.category_count(:color))
  
    assert_equal({"sweet"=>2, "tart"=>1},
                 a.category_count(:taste))
  
    assert_equal({"sweet"=>{"yellow"=>1, "green"=>1}, "tart"=>{"yellow"=>1}},
                 a.category_count(:taste, :color))
  end
end
