require 'tb'
require 'test/unit'
require 'tmpdir'

class TestTbReader < Test::Unit::TestCase
  def test_open
    Dir.mktmpdir {|d|
      open(ic="#{d}/c", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
        a,b
        1,3
      End
      open(it="#{d}/t", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
        a\tb
        1\t3
      End
      open(ij="#{d}/j", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
        [{"a":1,"b":3}]
      End
      Tb.open_reader("csv:#{ic}") {|r|
        header = nil
        all = []
        r.with_header {|h| header = h}.each {|pairs| all << pairs.map {|f, v| v } }
        assert_equal(%w[a b], header)
        assert_equal([%w[1 3]], all)
      }
      Tb.open_reader("tsv:#{it}") {|r|
        header = nil
        all = []
        r.with_header {|h| header = h}.each {|pairs| all << pairs.map {|f, v| v } }
        assert_equal(%w[a b], header)
        assert_equal([%w[1 3]], all)
      }
      Tb.open_reader("json:#{ij}") {|r|
        header = nil
        all = []
        r.with_header {|h| header = h}.each {|pairs| all << pairs.map {|f, v| v } }
        assert_equal(%w[a b], header)
        assert_equal([[1, 3]], all)
      }
      Tb.open_reader(ic) {|r|
        header = nil
        all = []
        r.with_header {|h| header = h}.each {|pairs| all << pairs.map {|f, v| v } }
        assert_equal(%w[a b], header)
        assert_equal([%w[1 3]], all)
      }
      assert_raise(ArgumentError) { Tb.open_reader(Object.new) }
    }
  end
end
