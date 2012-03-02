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

  def with_stderr(io)
    save = $stderr
    $stderr = io
    begin
      yield
    ensure
      $stderr = save
    end
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

  def test_debug_git_log_output_input
    system("git init -q")
    File.open("foo", "w") {|f| f.puts "bar" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git_log(['-o', o="o.csv", '--debug-git-log-output', g='gitlog'])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/,A,foo\n/, tb.get_record(0)["files"])
    gresult = File.read(g)
    assert(!gresult.empty?)
    FileUtils.rmtree('.git')
    Tb::Cmd.main_git_log(['-o', o="o.csv", '--debug-git-log-input', g])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/,A,foo\n/, tb.get_record(0)["files"])
  end

  def test_warn1
    system("git init -q")
    File.open("foo", "w") {|f| f.puts "bar" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git_log(['-o', o="o.csv", '--debug-git-log-output', g='gitlog'])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/,A,foo\n/, tb.get_record(0)["files"])
    gresult = File.binread(g)
    FileUtils.rmtree('.git')
    ###
    gresult.sub!(/^:.*foo$/, ':hoge')
    File.open(g, 'w') {|f| f.print gresult }
    o2 = 'o2.csv'
    File.open('log', 'w') {|log|
      with_stderr(log) {
        Tb::Cmd.main_git_log(['-o', o2, '--debug-git-log-input', g])
      }
    }
    result = File.read(o2)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_not_match(/,A,foo\n/, tb.get_record(0)["files"])
    log = File.read('log')
    assert(!log.empty?)
  end

  def test_warn2
    system("git init -q")
    File.open("foo", "w") {|f| f.puts "bar" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git_log(['-o', o="o.csv", '--debug-git-log-output', g='gitlog'])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/,A,foo\n/, tb.get_record(0)["files"])
    gresult = File.binread(g)
    FileUtils.rmtree('.git')
    ###
    gresult.sub!(/^author-name:/, 'author-name ')
    File.open(g, 'w') {|f| f.print gresult }
    o2 = 'o2.csv'
    File.open('log', 'w') {|log|
      with_stderr(log) {
        Tb::Cmd.main_git_log(['-o', o2, '--debug-git-log-input', g])
      }
    }
    result = File.read(o2)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/,A,foo\n/, tb.get_record(0)["files"])
    log = File.read('log')
    assert(!log.empty?)
  end

  def test_warn3
    system("git init -q")
    File.open("foo", "w") {|f| f.puts "bar" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git_log(['-o', o="o.csv", '--debug-git-log-output', g='gitlog'])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/,A,foo\n/, tb.get_record(0)["files"])
    gresult = File.binread(g)
    FileUtils.rmtree('.git')
    ###
    gresult.sub!(/end-commit/, 'endcommit')
    File.open(g, 'w') {|f| f.print gresult }
    o2 = 'o2.csv'
    File.open('log', 'w') {|log|
      with_stderr(log) {
        Tb::Cmd.main_git_log(['-o', o2, '--debug-git-log-input', g])
      }
    }
    result = File.read(o2)
    tb = Tb.parse_csv(result)
    assert_equal(0, tb.size)
    log = File.read('log')
    assert(!log.empty?)
  end

  def test_binary
    system("git init -q")
    File.open("foo", "w") {|f| f.print "\0\xff" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git_log(['-o', o="o.csv"])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/,,,A,foo\n/, tb.get_record(0)["files"])
  end

end
