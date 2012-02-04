require 'tb'
require 'test/unit'

class TestCustomEq < Test::Unit::TestCase
  def test_decreasing
    rel = lambda {|a, b| a > b }
    v1 = Tb::CustomEq.new(1, &rel)
    v2 = Tb::CustomEq.new(2, &rel)
    v3 = Tb::CustomEq.new(3, &rel)
    assert_equal(false, v1 == v1)
    assert_equal(false, v1 == v2)
    assert_equal(false, v1 == v3)
    assert_equal(true, v2 == v1)
    assert_equal(false, v2 == v2)
    assert_equal(false, v2 == v3)
    assert_equal(true, v3 == v1)
    assert_equal(true, v3 == v2)
    assert_equal(false, v3 == v3)
  end
end
