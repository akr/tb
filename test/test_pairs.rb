require 'tb'
require 'test/unit'

class TestTbPairs < Test::Unit::TestCase
  def test_initialize
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_kind_of(Tb::Pairs, tp)
  end

  def test_ref
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal(1, tp["a"])
    assert_equal(2, tp["b"])
    assert_equal(nil, tp["z"])
  end

  def test_each
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    result = []
    tp.each {|k, v|
      result << [k, v]
    }
    assert_equal([["a", 1], ["b", 2]], result)
  end

  def test_each_key
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    result = []
    tp.each_key {|k|
      result << k
    }
    assert_equal(["a", "b"], result)
  end

  def test_each_value
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    result = []
    tp.each_value {|v|
      result << v
    }
    assert_equal([1, 2], result)
  end

  def test_empty?
    tp = Tb::Pairs[[]]
    assert_equal(true, tp.empty?)
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal(false, tp.empty?)
  end

  def test_fetch
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal(false, tp.empty?)
    assert_equal(1, tp.fetch("a"))
    assert_raise(KeyError) { tp.fetch("z") }
    assert_equal(2, tp.fetch("b", 100))
    assert_equal(2, tp.fetch("b") { 200 })
    assert_equal(100, tp.fetch("z", 100))
    assert_equal(200, tp.fetch("z") { 200 })
    assert_raise(ArgumentError) { tp.fetch() }
    assert_raise(ArgumentError) { tp.fetch(1, 2, 3) }
  end

  def test_has_key?
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal(true, tp.has_key?("a"))
    assert_equal(false, tp.has_key?("z"))
  end

  def test_has_value?
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal(true, tp.has_value?(1))
    assert_equal(false, tp.has_value?(100))
  end

  def test_key
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal("b", tp.key(2))
    assert_equal(nil, tp.key(200))
  end

  def test_invert
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    tp2 = tp.invert
    assert_kind_of(Tb::Pairs, tp2)
    assert_equal([[1, "a"], [2, "b"]], tp2.to_a)
  end

  def test_keys
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal(["a", "b"], tp.keys)
  end

  def test_length
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal(2, tp.length)
  end

  def test_merge
    tp1 = Tb::Pairs[[["a", 1], ["b", 2]]]
    tp2 = Tb::Pairs[[["b", 3], ["c", 4]]]
    assert_equal([["a", 1], ["b", 3], ["c", 4]], tp1.merge(tp2).to_a)
    assert_equal([["a", 1], ["b", ["b", 2, 3]], ["c", 4]], tp1.merge(tp2) {|k, v1, v2| [k, v1, v2] }.to_a)
  end

  def test_reject
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal([["a", 1]], tp.reject {|k, v| k == "b" }.to_a)
    assert_equal([["b", 2]], tp.reject {|k, v| v == 1 }.to_a)
  end

  def test_values
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal([1, 2], tp.values)
  end

  def test_values_at
    tp = Tb::Pairs[[["a", 1], ["b", 2]]]
    assert_equal([1, 2], tp.values_at("a", "b"))
  end

end
