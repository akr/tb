require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdMheader < Test::Unit::TestCase
  def setup
    Tb::Cmd.reset_option
    @curdir = Dir.pwd
    @tmpdir = Dir.mktmpdir
  end
  def teardown
    Tb::Cmd.reset_option
    Dir.chdir @curdir
    FileUtils.rmtree @tmpdir
  end

  def test_basic
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
          ,2000,2000,2001,2001
      name,aaaa,bbbb,aaaa,bbbb
      x,1,2,3,4
      y,5,6,7,8
    End
    Tb::Cmd.main_mheader(['-o', o="o.csv", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      name,2000 aaaa,2000 bbbb,2001 aaaa,2001 bbbb
      x,1,2,3,4
      y,5,6,7,8
    End
  end
end
