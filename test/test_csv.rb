require 'tb'
require 'test/unit'
require_relative 'util_tbtest'

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

  def test_parse_empty_line_before_header
    empty_line = "\n"
    t = parse_csv(empty_line + <<-'End'.gsub(/^\s+/, ''))
    a,b
    1,2
    3,4
    End
    assert_equal(
      [{"a"=>"1", "b"=>"2"},
       {"a"=>"3", "b"=>"4"}],
      t)
  end

  def test_parse_empty_value
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

  def test_parse_newline
    t = parse_csv("\n")
    assert_equal([], t)
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

  def test_parse_ambiguous_header
    t = nil
    stderr = capture_stderr {
      t = parse_csv(<<-'End'.gsub(/^\s+/, ''))
      a,b,a,b,c
      0,1,2,3,4
      5,6,7,8,9
      End
    }
    assert_equal(
      [{"a"=>"0", "b"=>"1", "c"=>"4"},
       {"a"=>"5", "b"=>"6", "c"=>"9"}],
      t)
    assert_match(/Ambiguous header field/, stderr)
  end

  def test_parse_empty_header_field
    t = nil
    stderr = capture_stderr {
      t = parse_csv(<<-'End'.gsub(/^\s+/, ''))
      a,,c
      0,1,2
      5,6,7
      End
    }
    assert_equal(
      [{"a"=>"0", "c"=>"2"},
       {"a"=>"5", "c"=>"7"}],
      t)
    assert_match(/Empty header field/, stderr)
  end
end
