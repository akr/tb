require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdYAML < Test::Unit::TestCase
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
    Tb::Cmd.main_yaml(['-o', o="o.yaml", i])
    assert_equal(
      [
        {'a' => '0', 'b' => '1', 'c' => '2'},
        {'a' => '4', 'b' => '5', 'c' => '6'},
      ],
      YAML.load(File.read(o)))
  end
end
