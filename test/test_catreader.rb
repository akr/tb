require 'tb'
require 'test/unit'
require 'tmpdir'

class TestTbCatReader < Test::Unit::TestCase
  def test_open
    Dir.mktmpdir {|d|
      open(i1="#{d}/i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
        a,b
        1,2
      End
      open(i2="#{d}/i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
        b,a
        3,4
      End
      Tb::CatReader.open([i1, i2]) {|r|
        assert_equal(%w[a b], r.header)
        assert_equal([%w[1 2], %w[4 3]], r.read_all)
        assert_equal(0, r.index_from_field("a"))
        assert_equal("b", r.field_from_index(1))
        assert_equal(2, r.index_from_field_ex("1"))
        assert_equal("2", r.field_from_index_ex(3))
      }
    }
  end

end
