require 'tb'
require 'test/unit'

class TestTbLTSV < Test::Unit::TestCase
  def parse_ltsv(ltsv)
    Tb::LTSVReader.new(StringIO.new(ltsv)).to_a
  end

  def generate_ltsv(ary)
    writer = Tb::LTSVWriter.new(out = '')
    ary.each {|h| writer.put_hash h }
    writer.finish
    out
  end

  def test_escape_and_unescape
    0x00.upto(0x7f) {|c|
      s = [c].pack("C")
      assert_equal(s, Tb.ltsv_unescape_string(Tb.ltsv_escape_key(s)))
      assert_equal(s, Tb.ltsv_unescape_string(Tb.ltsv_escape_value(s)))
    }
  end

  def test_parse
    r = Tb::LTSVReader.new(StringIO.new("a:1\tb:2\na:3\tb:4\n"))
    result = []
    r.with_header {|header|
      result << header
    }.each {|obj|
      result << obj
    }
    assert_equal([%w[a b], {"a"=>"1", "b"=>"2"}, {"a"=>"3", "b"=>"4"}], result)
  end

  def test_parse2
    t = parse_ltsv("a:1\tb:2\n")
    assert_equal(
      [{"a"=>"1", "b"=>"2"}],
      t)
  end

  def test_generate_ltsv
    t = [{'a' => 'foo', 'b' => 'bar'}]
    assert_equal("a:foo\tb:bar\n", generate_ltsv(t))
  end

  def test_generate_ltsv2
    t = [{'a' => 'foo', 'b' => 'bar'},
         {'a' => 'q', 'b' => 'w'}]
    assert_equal("a:foo\tb:bar\na:q\tb:w\n", generate_ltsv(t))
  end

end
