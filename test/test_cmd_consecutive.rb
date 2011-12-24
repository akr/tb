require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdConsecutive < Test::Unit::TestCase
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
      1,2,3
      4,5,6
      7,8,9
    End
    Tb::Cmd.main_consecutive(['-o', o="o.csv", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a_1,a_2,b_1,b_2,c_1,c_2
      1,4,2,5,3,6
      4,7,5,8,6,9
    End
  end

  def test_numeric
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      1,2,3
      4,5,6
      7,8,9
    End
    Tb::Cmd.main_consecutive(['-o', o="o.csv", '-N', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,1,b,2,c,3
      1,4,2,5,3,6
      4,7,5,8,6,9
    End
  end

  def test_extend
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2,3
      4,5,6
      7,8,9
    End
    Tb::Cmd.main_consecutive(['-o', o="o.csv", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a_1,a_2,b_1,b_2
      1,4,2,5,3,6
      4,7,5,8,6,9
    End
  end

end
