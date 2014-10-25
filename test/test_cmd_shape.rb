require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdShape < Test::Unit::TestCase
  def setup
    Tb::Cmd.reset_option
    @curdir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir @tmpdir
  end
  def teardown
    Tb::Cmd.reset_option
    Dir.chdir @curdir
    FileUtils.rmtree @tmpdir
  end

  def test_ndjson
    File.open(i="i.ndjson", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      {"a":0, "b":1}
      {"a":4, "b":5, "c":6}
    End
    Tb::Cmd.main_shape(['-o', o="o.csv", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      filename,records,min_pairs,max_pairs
      i.ndjson,2,2,3
    End
  end

  def test_csv
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      0,1
      4,5,6
    End
    Tb::Cmd.main_shape(['-o', o="o.csv", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      filename,records,min_pairs,max_pairs,header_fields,min_fields,max_fields
      i.csv,2,2,3,3,2,3
    End
  end

  def test_output_ndjson
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      0,1
      4,5,6
    End
    Tb::Cmd.main_shape(['-o', o="o.ndjson", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      {"filename":"i.csv","records":2,"min_pairs":2,"max_pairs":3,"header_fields":3,"min_fields":2,"max_fields":3}
    End
  end

  def test_extra_field
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      0,1
      4,5,6,7
    End
    Tb::Cmd.main_shape(['-o', o="o.csv", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      filename,records,min_pairs,max_pairs,header_fields,min_fields,max_fields
      i.csv,2,2,3,3,2,4
    End
  end

  def test_twofile
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a
      1
      3
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b,a
      5,6
      7,8
    End
    Tb::Cmd.main_shape(['-o', o="o.csv", i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      filename,records,min_pairs,max_pairs,header_fields,min_fields,max_fields
      i1.csv,2,1,1,1,1,1
      i2.csv,2,2,2,2,2,2
    End
  end

end
