require 'tb'
require 'test/unit'

class TestTbJSON < Test::Unit::TestCase
  def test_parse
    r = Tb::JSONReader.new('[{"a":1, "b":2}, {"a":3, "b":4}]')
    result = []
    r.header_and_each(lambda {|header| result << header}) {|obj|
      result << obj
    }
    assert_equal([nil, {"a"=>1, "b"=>2}, {"a"=>3, "b"=>4}], result)
  end
end
