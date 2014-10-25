require 'tb'
require 'test/unit'

class TestTbJSONL < Test::Unit::TestCase
  def parse_jsonl(csv)
    Tb::JSONLReader.new(StringIO.new(csv)).to_a
  end

  def generate_jsonl(ary)
    writer = Tb::JSONLWriter.new(out = '')
    ary.each {|h| writer.put_hash h }
    writer.finish
    out
  end

  def test_reader
    jsonl = <<-'End'
      {"A":"a","B":"b","C":"c"}
      {"A":"d","B":"e","C":"f"}
    End
    reader = Tb::JSONLReader.new(StringIO.new(jsonl))
    assert_equal({"A"=>"a", "B"=>"b", "C"=>"c"}, reader.get_hash)
    assert_equal({"A"=>"d", "B"=>"e", "C"=>"f"}, reader.get_hash)
    assert_equal(nil, reader.get_hash)
    assert_equal(nil, reader.get_hash)
  end

  def test_reader_header
    jsonl = <<-'End'
      {"A":"a"}
      {"A":"d","B":"e","C":"f"}
    End
    reader = Tb::JSONLReader.new(StringIO.new(jsonl))
    assert_equal(%w[A B C], reader.get_named_header)
    assert_equal({"A"=>"a"}, reader.get_hash)
    assert_equal({"A"=>"d", "B"=>"e", "C"=>"f"}, reader.get_hash)
    assert_equal(nil, reader.get_hash)
    assert_equal(nil, reader.get_hash)
  end

  def test_writer
    arys = []
    writer = Tb::JSONLWriter.new(arys)
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
    assert_equal('{"r":"\r","n":"\n"}'+"\n", generate_jsonl([{"r"=>"\r", "n"=>"\n"}]))
  end

end
