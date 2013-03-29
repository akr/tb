require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdToLTSV < Test::Unit::TestCase
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
    Tb::Cmd.main_to_ltsv(['-o', o="o.ltsv", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a:0\tb:1\tc:2
      a:4\tb:5\tc:6
    End
  end

  def test_numeric
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      0,1,2
      4,5,6
    End
    Tb::Cmd.main_to_ltsv(['-o', o="o.ltsv", '-N', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      1:a\t2:b\t3:c
      1:0\t2:1\t3:2
      1:4\t2:5\t3:6
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
    Tb::Cmd.main_to_ltsv(['-o', o="o.ltsv", i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a:1\tb:2
      a:3\tb:4
      a:6\tb:5
      a:8\tb:7
    End
  end

end
