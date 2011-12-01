require 'tb'
require 'test/unit'

class TestTbTSV < Test::Unit::TestCase
  def test_parse
    tsv = "a\tb\n1\t2\n"
    t = Tb.parse_tsv(tsv)
    records = []
    t.each_record {|record|
      records << record.to_h_with_reserved
    }
    assert_equal(
      [{"_recordid"=>0, "a"=>"1", "b"=>"2"}],
      records)
  end

  def test_parse_conv
    tsv = "foo\na\tb\n1\t2\n"
    t = Tb.parse_tsv(tsv) {|aa|
      assert_equal([%w[foo],
                   %w[a b],
                   %w[1 2]],
                   aa)
      aa.shift
      aa
    }
    records = []
    t.each_record {|record|
      records << record.to_h_with_reserved
    }
    assert_equal(
      [{"_recordid"=>0, "a"=>"1", "b"=>"2"}],
      records)
  end

  def test_generate_tsv
    tbl = Tb.new %w[a b], %w[foo bar]
    tbl.generate_tsv(out="")
    assert_equal("a\tb\nfoo\tbar\n", out)
  end
end
