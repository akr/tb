require 'tb'
require 'test/unit'

class TestTbLTSV < Test::Unit::TestCase
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
    ltsv = "a:1\tb:2\n"
    t = Tb.parse_ltsv(ltsv)
    records = []
    t.each_record {|record|
      records << record.to_h_with_reserved
    }
    assert_equal(
      [{"_recordid"=>0, "a"=>"1", "b"=>"2"}],
      records)
  end

  def test_generate_ltsv
    tbl = Tb.new %w[a b], %w[foo bar]
    tbl.generate_ltsv(out="")
    assert_equal("a:foo\tb:bar\n", out)
  end

  def test_generate_ltsv_with_block
    tbl = Tb.new %w[a b], %w[foo bar], %w[q w]
    tbl.generate_ltsv(out="") {|recids| recids.reverse }
    assert_equal("a:q\tb:w\na:foo\tb:bar\n", out)
  end

end
