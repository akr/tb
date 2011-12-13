require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdPNM < Test::Unit::TestCase
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
    File.open(i="i.ppm", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      P1
      2 3
      10
      11
      01
    End
    Tb::Cmd.main_pnm(['-o', o="o.ppm", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      P1
      2 3
      10
      11
      01
    End
  end
end
