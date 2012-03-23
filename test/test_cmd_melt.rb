require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdMelt < Test::Unit::TestCase
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
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    Tb::Cmd.main_melt(['-o', o="o.csv", 'a,b', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,variable,value
      0,1,c,2
      0,1,d,3
      4,5,c,6
      4,5,d,7
      8,9,c,a
      8,9,d,b
      c,d,c,e
      c,d,d,f
    End
  end
end
