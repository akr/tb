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
    items = []
    t.each_item {|item|
      items << item
    }
    assert_equal(
      [{"_itemid"=>0, "a"=>"1", "b"=>"2"},
       {"_itemid"=>1, "a"=>"3", "b"=>"4"}],
      items)
  end

  def test_parse_empty
    csv = <<-'End'.gsub(/^\s+/, '')
    a,b,c
    1,,2
    3,"",4
    End
    t = Table.parse_csv(csv)
    items = []
    t.each_item {|item|
      items << item
    }
    assert_equal(
      [{"_itemid"=>0, "a"=>"1", "c"=>"2"},
       {"_itemid"=>1, "a"=>"3", "b"=>"", "c"=>"4"}],
      items)
  end

  def test_generate
    t = Table.new
    t.insert({"a"=>1, "b"=>2})
    t.insert({"a"=>3, "b"=>4})
    out = t.generate_csv('', ['a', 'b'])
    assert_equal(<<-'End'.gsub(/^\s+/, ''), out)
    a,b
    1,2
    3,4
    End
  end

  def test_generate_empty
    t = Table.new
    t.insert({"a"=>1, "b"=>nil, "c"=>2})
    t.insert({"a"=>3, "b"=>"", "c"=>4})
    out = t.generate_csv('', ['a', 'b', 'c'])
    assert_equal(<<-'End'.gsub(/^\s+/, ''), out)
    a,b,c
    1,,2
    3,"",4
    End
  end

end
