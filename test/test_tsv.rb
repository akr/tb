require 'tb'
require 'test/unit'

class TestTbTSV < Test::Unit::TestCase
  def parse_tsv(tsv)
    Tb::HeaderTSVReader.new(StringIO.new(tsv)).to_a
  end

  def generate_tsv(ary)
    writer = Tb::HeaderTSVWriter.new(out = '')
    ary.each {|h| writer.put_hash h }
    writer.finish
    out
  end

  def test_parse
    tsv = "a\tb\n1\t2\n"
    ary = parse_tsv(tsv)
    assert_equal(
      [{"a"=>"1", "b"=>"2"}],
      ary)
  end

  def test_parse2
    tsv = "a\tb\n" + "1\t2\n" + "3\t4\n"
    ary = parse_tsv(tsv)
    assert_equal(
      [{"a"=>"1", "b"=>"2"}, {"a"=>"3", "b"=>"4"}],
      ary)
  end

  def test_generate_tsv
    t = [{'a' => 'foo', 'b' => 'bar'}]
    assert_equal("a\tb\nfoo\tbar\n", generate_tsv(t))
  end

end
