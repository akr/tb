require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdTarTvf < Test::Unit::TestCase
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

  def gnu_tar
    return @@gnu_tar if defined? @@gnu_tar
    commands = %w[gtar tar]
    commands.each {|c|
      msg = IO.popen("LC_ALL=C #{c} --help 1>&2") {|f| f.read }
      if /GNU/ =~ msg
        @@gnu_tar = c
        return @@gnu_tar
      end
    }
    @@gnu_tar = nil
  end

  def test_basic
    open('foo', 'w') {|f| }
    assert(system('tar cf bar.tar foo'))
    Tb::Cmd.main_tar_tvf(['-o', o='o.csv', 'bar.tar'])
    assert_match(/,foo,/, File.read(o))
  end
end
