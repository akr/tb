require 'tb'
require 'test/unit'

class TestTbCSV < Test::Unit::TestCase
  def parse_csv(csv)
    Tb::HeaderCSVReader.new(StringIO.new(csv)).to_a
  end

  def generate_csv(ary)
    writer = Tb::HeaderCSVWriter.new(out = '')
    ary.each {|h| writer.put_hash h }
    writer.finish
    out
  end

  def test_parse
    t = parse_csv(<<-'End'.gsub(/^\s+/, ''))
    a,b
    1,2
    3,4
    End
    assert_equal(
      [{"a"=>"1", "b"=>"2"},
       {"a"=>"3", "b"=>"4"}],
      t)
  end

  def test_parse_empty
    t = parse_csv(<<-'End'.gsub(/^\s+/, ''))
    a,b,c
    1,,2
    3,"",4
    End
    assert_equal(
      [{"a"=>"1", "b"=>nil, "c"=>"2"},
       {"a"=>"3", "b"=>"", "c"=>"4"}],
      t)
  end

  def test_generate
    t = [{'a' => 1, 'b' => 2},
         {'a' => 3, 'b' => 4}]
    assert_equal(<<-'End'.gsub(/^\s+/, ''), generate_csv(t))
    a,b
    1,2
    3,4
    End
  end

  def test_generate_empty
    t = [{'a' => 1, 'b' => nil, 'c' => 2},
         {'a' => 3, 'b' => '',  'c' => 4}]
    assert_equal(<<-'End'.gsub(/^\s+/, ''), generate_csv(t))
    a,b,c
    1,,2
    3,"",4
    End
  end

end
