require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdNewfield < Test::Unit::TestCase
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
      a,b
      1,2
      3,4
    End
    Tb::Cmd.main_newfield(['-o', o="o.csv", 'c', '_["a"].to_i + _["b"].to_i', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      c,a,b
      3,1,2
      7,3,4
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
    Tb::Cmd.main_newfield(['-o', o="o.csv", 'c', '_["a"].to_i - _["b"].to_i', i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      c,a,b
      -1,1,2
      -1,3,4
      1,6,5
      1,8,7
    End
  end

end
