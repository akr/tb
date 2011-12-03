require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdGroup < Test::Unit::TestCase
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
      x,5,6,y
    End
    assert_equal(true, Tb::Cmd.main_group(['-o', o="o.csv", 'b,c', '-a', 'count', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      b,c,count
      1,2,1
      5,6,2
      9,a,1
      d,e,1
    End
  end
end
