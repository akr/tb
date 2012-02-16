require 'tb'
require 'test/unit'

class TestZipper < Test::Unit::TestCase
  def test_basic
    z = Tb::Zipper.new([Tb::Func::Sum, Tb::Func::Min])
    assert_equal([5,2], z.aggregate(z.call(z.start([2,3]), z.start([3,2]))))
  end

  def test_argerr
    z = Tb::Zipper.new([Tb::Func::Sum, Tb::Func::Min])
    assert_raise(ArgumentError) { z.start([]) }
    assert_raise(ArgumentError) { z.start([1]) }
    assert_raise(ArgumentError) { z.start([1,2,3]) }
    assert_raise(ArgumentError) { z.call([1], [3]) }
    assert_raise(ArgumentError) { z.call([1], [3,4]) }
    assert_raise(ArgumentError) { z.call([1,2], [3]) }
    assert_raise(ArgumentError) { z.aggregate([]) }
    assert_raise(ArgumentError) { z.aggregate([1]) }
    assert_raise(ArgumentError) { z.aggregate([1,2,3]) }
  end
end
