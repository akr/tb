require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdTSV < Test::Unit::TestCase
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
      0,1,2
      4,5,6
    End
    Tb::Cmd.main_tsv(['-o', o="o.tsv", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a\tb\tc
      0\t1\t2
      4\t5\t6
    End
  end

  def test_numeric
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      0,1,2
      4,5,6
    End
    Tb::Cmd.main_tsv(['-o', o="o.tsv", '-N', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a\tb\tc
      0\t1\t2
      4\t5\t6
    End
  end

  def test_twofile
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2
      3,4
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b,a
      5,6
      7,8
    End
    Tb::Cmd.main_tsv(['-o', o="o.csv", i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a\tb
      1\t2
      3\t4
      6\t5
      8\t7
    End
  end

end
