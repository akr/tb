require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdCrop < Test::Unit::TestCase
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
    Tb::Cmd.main_crop(['-o', o="o.csv", '-r', 'B2:C3', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      1,2
      5,6
    End
  end
end
