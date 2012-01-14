require 'tb'
require 'test/unit'

class TestRevCmp < Test::Unit::TestCase
  def test_cmp
    assert_equal(2 <=> 1, Tb::RevCmp.new(1) <=> Tb::RevCmp.new(2))
    assert_equal(1 <=> 2, Tb::RevCmp.new(2) <=> Tb::RevCmp.new(1))
    assert_equal(3 <=> 3, Tb::RevCmp.new(3) <=> Tb::RevCmp.new(3))
  end
end
