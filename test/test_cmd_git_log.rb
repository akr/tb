require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdGitLog < Test::Unit::TestCase
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
    system("git init -q")
    File.open("foo", "w") {|f| f.puts "bar" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git_log(['-o', o="o.csv"])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/,A,foo\n/, tb.get_record(0)["files"])
  end

  def test_escaped_filename
    filename = (1..32).to_a.pack("C*") + "\"\\"
    system("git init -q")
    File.open(filename, "w") {|f| f.puts "bar" }
    system("git", "add", filename)
    system("git", "commit", "-q", "-m", "msg", filename)
    Tb::Cmd.main_git_log(['-o', o="o.csv"])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/,A,/, tb.get_record(0)["files"])
    ftb = Tb.parse_csv(tb.get_record(0)["files"])
    assert_equal(1, ftb.size)
    assert_equal(filename, ftb.get_record(0)["filename"])
  end

end
