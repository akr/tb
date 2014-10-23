require 'tb'
require 'test/unit'
require 'tmpdir'

class TestTbReader < Test::Unit::TestCase
=begin
  def test_load_csv
    Dir.mktmpdir {|d|
      open(i="#{d}/i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
        a,b
        1,3
        2,4
      End
      t = Tb.load_csv(i)
      records = []
      t.each_record {|record| records << record.to_h }
      assert_equal(
        [{"a"=>"1", "b"=>"3"},
         {"a"=>"2", "b"=>"4"}],
        records)
    }
  end

  def test_load_tsv
    Dir.mktmpdir {|d|
      open(i="#{d}/i.tsv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
        a\tb
        1\t3
        2\t4
      End
      t = Tb.load_tsv(i)
      records = []
      t.each_record {|record| records << record.to_h }
      assert_equal(
        [{"a"=>"1", "b"=>"3"},
         {"a"=>"2", "b"=>"4"}],
        records)
    }
  end

  def test_parse_csv
    csv = <<-'End'.gsub(/^[ \t]+/, '')
    1,2
    3,4
    End
    t = Tb.parse_csv(csv, 'a', 'b')
    records = []
    t.each_record {|record|
      records << record.to_h
    }
    assert_equal(
      [{"a"=>"1", "b"=>"2"},
       {"a"=>"3", "b"=>"4"}],
      records)
  end

  def test_parse_tsv
    csv = <<-"End".gsub(/^[ \t]+/, '')
    1\t2
    3\t4
    End
    t = Tb.parse_tsv(csv, 'a', 'b')
    records = []
    t.each_record {|record|
      records << record.to_h
    }
    assert_equal(
      [{"a"=>"1", "b"=>"2"},
       {"a"=>"3", "b"=>"4"}],
      records)
  end
=end

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

=begin
  def test_header_ignore_empty
    csv = "\n" + <<-'End'.gsub(/^[ \t]+/, '')
    a,b
    1,2
    3,4
    End
    t = Tb.parse_csv(csv)
    records = []
    t.each_record {|record|
      records << record.to_h
    }
    assert_equal(
      [{"a"=>"1", "b"=>"2"},
       {"a"=>"3", "b"=>"4"}],
      records)
  end

  def test_header_empty_only
    csv = "\n"
    t = Tb.parse_csv(csv)
    records = []
    t.each_record {|record|
      records << record.to_h
    }
    assert_equal([], records)
  end
=end

end
