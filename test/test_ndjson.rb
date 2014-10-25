require 'tb'
require 'test/unit'

class TestTbNDJSON < Test::Unit::TestCase
  def parse_ndjson(ndjson)
    Tb::NDJSONReader.new(StringIO.new(ndjson)).to_a
  end

  def generate_ndjson(ary)
    writer = Tb::NDJSONWriter.new(out = '')
    ary.each {|h| writer.put_hash h }
    writer.finish
    out
  end

  def test_reader
    ndjson = <<-'End'
      {"A":"a","B":"b","C":"c"}
      {"A":"d","B":"e","C":"f"}
    End
    reader = Tb::NDJSONReader.new(StringIO.new(ndjson))
    assert_equal({"A"=>"a", "B"=>"b", "C"=>"c"}, reader.get_hash)
    assert_equal({"A"=>"d", "B"=>"e", "C"=>"f"}, reader.get_hash)
    assert_equal(nil, reader.get_hash)
    assert_equal(nil, reader.get_hash)
  end

  def test_reader_header
    ndjson = <<-'End'
      {"A":"a"}
      {"A":"d","B":"e","C":"f"}
    End
    reader = Tb::NDJSONReader.new(StringIO.new(ndjson))
    assert_equal(%w[A B C], reader.get_named_header)
    assert_equal({"A"=>"a"}, reader.get_hash)
    assert_equal({"A"=>"d", "B"=>"e", "C"=>"f"}, reader.get_hash)
    assert_equal(nil, reader.get_hash)
    assert_equal(nil, reader.get_hash)
  end

  def test_writer
    arys = []
    writer = Tb::NDJSONWriter.new(arys)
    writer.header_generator = lambda { flunk }
    assert_equal([], arys)
    writer.put_hash({"A"=>"a", "B"=>"b", "C"=>"c"})
    assert_equal(['{"A":"a","B":"b","C":"c"}'+"\n"], arys)
    writer.put_hash({"A"=>"d", "B"=>"e", "C"=>"f"})
    assert_equal(['{"A":"a","B":"b","C":"c"}'+"\n", '{"A":"d","B":"e","C":"f"}'+"\n"], arys)
    writer.finish
    assert_equal(['{"A":"a","B":"b","C":"c"}'+"\n", '{"A":"d","B":"e","C":"f"}'+"\n"], arys)
  end

  def test_newline_in_string
    assert_equal('{"r":"\r","n":"\n"}'+"\n", generate_ndjson([{"r"=>"\r", "n"=>"\n"}]))
  end

  def test_empty_line
    assert_equal([{"a"=>"1"}, {"a"=>"2"}], parse_ndjson('{"a":"1"}'+"\n\n" + '{"a":"2"}'+"\n"))
  end

end
