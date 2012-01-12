require 'tb'
require 'test/unit'

class TestTbJSON < Test::Unit::TestCase
  def test_parse
    r = Tb::JSONReader.new('[{"a":1, "b":2}, {"a":3, "b":4}]')
    result = []
    r.with_header {|header|
      result << header
    }.each {|obj|
      result << obj
    }
    assert_equal([nil, {"a"=>1, "b"=>2}, {"a"=>3, "b"=>4}], result)
  end
end
