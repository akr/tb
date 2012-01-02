require 'tb'
require 'test/unit'
require 'tmpdir'

class TestTbEnum < Test::Unit::TestCase
  def test_fileenumerator
    obj = [1,2,3]
    obj.extend Tb::Enum
    en = obj.fileenumerator
    ary = []
    en.each {|v|
      ary << v
    }
    assert_equal([1, 2, 3], ary)
  end

  def test_write_to_csv_basic
    obj = [
      [['a', 0], ['b', 1], ['c', 2]],
      [['a', 3], ['b', 4], ['c', 5]],
      [['a', 6], ['b', 7], ['c', 8]],
    ]
    obj.extend Tb::Enum
    Dir.mktmpdir {|d|
      obj.write_to_csv("#{d}/foo.csv")
      assert_equal(<<-'End'.gsub(/^\s*/, ''), File.read("#{d}/foo.csv"))
        a,b,c
        0,1,2
        3,4,5
        6,7,8
      End
    }
  end

  def test_write_to_csv_header_extension
    obj = [
      [['a', 0]],
      [['b', 1]],
      [['c', 2]],
    ]
    obj.extend Tb::Enum
    Dir.mktmpdir {|d|
      obj.write_to_csv("#{d}/foo.csv")
      assert_equal(<<-'End'.gsub(/^\s*/, ''), File.read("#{d}/foo.csv"))
        a,b,c
        0
        ,1
        ,,2
      End
    }
  end

  def test_write_to_csv_without_header
    obj = [
      [['a', 0]],
      [['b', 1]],
      [['c', 2]],
    ]
    obj.extend Tb::Enum
    Dir.mktmpdir {|d|
      obj.write_to_csv("#{d}/foo.csv", false)
      assert_equal(<<-'End'.gsub(/^\s*/, ''), File.read("#{d}/foo.csv"))
        0
        ,1
        ,,2
      End
    }
  end

end
