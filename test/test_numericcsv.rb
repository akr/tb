require 'tb'
require 'test/unit'

class TestTbNumericCSV < Test::Unit::TestCase
  def test_reader
    csv = <<-'End'.gsub(/^\s*/, '')
      A,B,C
      a,b,c
      d,e,f
    End
    reader = Tb::NumericCSVReader.new(StringIO.new(csv))
    assert_equal({"1"=>"A", "2"=>"B", "3"=>"C"}, reader.get_hash)
    assert_equal({"1"=>"a", "2"=>"b", "3"=>"c"}, reader.get_hash)
    assert_equal({"1"=>"d", "2"=>"e", "3"=>"f"}, reader.get_hash)
    assert_equal(nil, reader.get_hash)
    assert_equal(nil, reader.get_hash)
  end

  def test_writer
    arys = []
    writer = Tb::NumericCSVWriter.new(arys)
    writer.put_hash({"1"=>"A", "2"=>"B", "3"=>"C"})
    assert_equal(["A,B,C\n"], arys)
    writer.put_hash({"1"=>"a", "2"=>"b", "3"=>"c"})
    assert_equal(["A,B,C\n", "a,b,c\n"], arys)
    writer.put_hash({"1"=>"d", "2"=>"e", "3"=>"f"})
    assert_equal(["A,B,C\n", "a,b,c\n", "d,e,f\n"], arys)
  end

  def test_writer_invalid_field
    arys = []
    writer = Tb::NumericCSVWriter.new(arys)
    assert_raise(ArgumentError) { writer.put_hash({"A"=>"1"}) }
  end

end
