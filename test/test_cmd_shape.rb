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

  def test_basic
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      0,1
      4,5,6,7
    End
    assert_equal(true, Tb::Cmd.main_shape(['-o', o="o.csv", i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      header_fields,min_fields,max_fields,records,filename
      3,2,4,2,i.csv
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
    assert_equal(true, Tb::Cmd.main_shape(['-o', o="o.csv", i1, i2]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      header_fields,min_fields,max_fields,records,filename
      1,1,1,2,i1.csv
      2,2,2,2,i2.csv
    End
  end

end
