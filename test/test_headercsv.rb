require 'tb'
require 'test/unit'

class TestTbHeaderCSV < Test::Unit::TestCase
  def test_reader
    arys = [
      %w[A B C],
      %w[a b c],
      %w[d e f],
    ]
    reader = Tb::HeaderCSVReader.new(arys)
    assert_equal({"A"=>"a", "B"=>"b", "C"=>"c"}, reader.get_hash)
    assert_equal({"A"=>"d", "B"=>"e", "C"=>"f"}, reader.get_hash)
    assert_equal(nil, reader.get_hash)
    assert_equal(nil, reader.get_hash)
  end

  def test_writer
    arys = []
    writer = Tb::HeaderCSVWriter.new(arys)
    assert_equal([], arys)
    writer.put_hash({"A"=>"a", "B"=>"b", "C"=>"c"})
    assert_equal([], arys)
    writer.put_hash({"A"=>"d", "B"=>"e", "C"=>"f"})
    assert_equal([], arys)
    writer.finish
    assert_equal(["A,B,C\n", "a,b,c\n", "d,e,f\n"], arys)
  end

  def test_writer_known_header
    arys = []
    writer = Tb::HeaderCSVWriter.new(arys)
    writer.header_generator = lambda { %w[A B C] }
    assert_equal([], arys)
    writer.put_hash({"A"=>"a", "B"=>"b", "C"=>"c"})
    assert_equal(["A,B,C\n", "a,b,c\n"], arys)
    writer.put_hash({"A"=>"d", "B"=>"e", "C"=>"f"})
    assert_equal(["A,B,C\n", "a,b,c\n", "d,e,f\n"], arys)
    writer.finish
    assert_equal(["A,B,C\n", "a,b,c\n", "d,e,f\n"], arys)
  end

end
