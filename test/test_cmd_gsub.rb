require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdGsub < Test::Unit::TestCase
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
      a,b,c
      foo,bar,baz
      qux,quuux
    End
    Tb::Cmd.main_gsub(['-o', o="o.csv", '[au]', 'YY', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      foo,bYYr,bYYz
      qYYx,qYYYYYYx
    End
  end
end
