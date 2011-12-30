require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdNest < Test::Unit::TestCase
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
      0,1,2
      0,3,4
      4,5,6
    End
    Tb::Cmd.main_nest(['-o', o="o.csv", 'z,b,c', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,z
      0,"b,c
      1,2
      3,4
      "
      4,"b,c
      5,6
      "
    End
  end

  def test_field_not_found
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      0,1,2
      0,3,4
      4,5,6
    End
    exc = assert_raise(SystemExit) { Tb::Cmd.main_nest(['-o', o="o.csv", 'z,b,d', i]) }
    assert(!exc.success?)
  end

end
