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
        assert_equal(nil, r.header_fixed)
        assert_equal([[['a','1'], ['b','2']], [['b','3'],['a','4']]], r.to_a.map {|pairs| pairs.to_a })
        assert_equal(%w[a b], r.header_fixed)
      }
    }
  end

end
