require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdUtil < Test::Unit::TestCase
  def setup
    Tb::Cmd.reset_option
    #@curdir = Dir.pwd
    #@tmpdir = Dir.mktmpdir
    #Dir.chdir @tmpdir
  end
  def teardown
    Tb::Cmd.reset_option
    #Dir.chdir @curdir
    #FileUtils.rmtree @tmpdir
  end

  def test_def_vhelp
    verbose_help = Tb::Cmd.instance_variable_get(:@verbose_help)
    verbose_help['foo'] = 'bar'
    begin
      assert_raise(ArgumentError) { Tb::Cmd.def_vhelp('foo', 'baz') }
    ensure
      verbose_help.delete 'foo'
    end
  end

end
