require 'table'
require 'test/unit'

class TestTableCSV < Test::Unit::TestCase
  def test_parse
    csv = <<-'End'.gsub(/^\s+/, '')
    a,b
    1,2
    3,4
    End
    t = Table.parse_csv(csv)
    records = []
    t.each_record {|record|
      records << record.to_h_with_reserved
    }
    assert_equal(
      [{"_recordid"=>0, "a"=>"1", "b"=>"2"},
       {"_recordid"=>1, "a"=>"3", "b"=>"4"}],
      records)
  end

  def test_parse_empty
    csv = <<-'End'.gsub(/^\s+/, '')
    a,b,c
    1,,2
    3,"",4
    End
    t = Table.parse_csv(csv)
    records = []
    t.each_record {|record|
      records << record.to_h_with_reserved
    }
    assert_equal(
      [{"_recordid"=>0, "a"=>"1", "c"=>"2"},
       {"_recordid"=>1, "a"=>"3", "b"=>"", "c"=>"4"}],
      records)
  end

  def test_parse_conv
    csv = "foo\na,b\n1,2\n"
    t = Table.parse_csv(csv) {|aa|
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

  def test_generate
    t = Table.new %w[a b], [1, 2], [3, 4]
    out = t.generate_csv('', ['a', 'b'])
    assert_equal(<<-'End'.gsub(/^\s+/, ''), out)
    a,b
    1,2
    3,4
    End
  end

  def test_generate_empty
    t = Table.new %w[a b c], [1, nil, 2], [3, '', 4]
    out = t.generate_csv('', ['a', 'b', 'c'])
    assert_equal(<<-'End'.gsub(/^\s+/, ''), out)
    a,b,c
    1,,2
    3,"",4
    End
  end

end
