require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdToYAML < Test::Unit::TestCase
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
      4,5,6
    End
    Tb::Cmd.main_to_yaml(['-o', o="o.yaml", i])
    assert_equal(
      [
        {'a' => '0', 'b' => '1', 'c' => '2'},
        {'a' => '4', 'b' => '5', 'c' => '6'},
      ],
      YAML.load(File.read(o)))
  end

  def test_twofile
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2
      3,4
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b,a
      5,6
      7,8
    End
    Tb::Cmd.main_to_yaml(['-o', o="o.csv", i1, i2])
    assert_equal(
      [
        {'a' => '1', 'b' => '2'},
        {'a' => '3', 'b' => '4'},
        {'a' => '6', 'b' => '5'},
        {'a' => '8', 'b' => '7'},
      ],
      YAML.load(File.read(o)))
  end

end
