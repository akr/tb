require 'tb'
require 'test/unit'

class TestCustomCmp < Test::Unit::TestCase
  def test_revcmp
    cmp = lambda {|a, b| b <=> a }
    v1 = Tb::CustomCmp.new(1, &cmp)
    v2 = Tb::CustomCmp.new(2, &cmp)
    v3 = Tb::CustomCmp.new(3, &cmp)
    assert_equal(2 <=> 1, v1 <=> v2)
    assert_equal(1 <=> 2, v2 <=> v1)
    assert_equal(3 <=> 3, v3 <=> v3)
  end
end
