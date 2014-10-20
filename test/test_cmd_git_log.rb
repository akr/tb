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
    Tb::Cmd.main_git(['-o', o="o.csv"])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/,A,foo\n/, row[header.index "files"])
  end

  def test_escaped_filename
    filename = (1..32).to_a.pack("C*") + "\"\\"
    system("git init -q")
    File.open(filename, "w") {|f| f.puts "bar" }
    system("git", "add", filename)
    system("git", "commit", "-q", "-m", "msg", filename)
    Tb::Cmd.main_git(['-o', o="o.csv"])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/,A,/, row[header.index "files"])
    faa = CSV.parse(row[header.index "files"])
    assert_equal(2, faa.length)
    fheader, frow = faa
    assert_equal(filename, frow[fheader.index "filename"])
  end

  def test_debug_git_output_input
    system("git init -q")
    File.open("foo", "w") {|f| f.puts "bar" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git(['-o', o="o.csv", '--debug-git-output', g='gitlog'])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/,A,foo\n/, row[header.index "files"])
    gresult = File.read(g)
    assert(!gresult.empty?)
    FileUtils.rmtree('.git')
    Tb::Cmd.main_git(['-o', o="o.csv", '--debug-git-input', g])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/,A,foo\n/, row[header.index "files"])
  end

  def test_warn1
    system("git init -q")
    File.open("foo", "w") {|f| f.puts "bar" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git(['-o', o="o.csv", '--debug-git-output', g='gitlog'])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/,A,foo\n/, row[header.index "files"])
    gresult = File.binread(g)
    FileUtils.rmtree('.git')
    ###
    gresult.sub!(/^:.*foo$/, ':hoge')
    File.open(g, 'w') {|f| f.print gresult }
    o2 = 'o2.csv'
    File.open('log', 'w') {|log|
      with_stderr(log) {
        Tb::Cmd.main_git(['-o', o2, '--debug-git-input', g])
      }
    }
    aa = CSV.read(o2)
    assert_equal(2, aa.length)
    header, row = aa
    assert_not_match(/,A,foo\n/, row[header.index "files"])
    log = File.read('log')
    assert(!log.empty?)
  end

  def test_warn2
    system("git init -q")
    File.open("foo", "w") {|f| f.puts "bar" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git(['-o', o="o.csv", '--debug-git-output', g='gitlog'])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/,A,foo\n/, row[header.index "files"])
    gresult = File.binread(g)
    FileUtils.rmtree('.git')
    ###
    gresult.sub!(/^author-name:/, 'author-name ')
    File.open(g, 'w') {|f| f.print gresult }
    o2 = 'o2.csv'
    File.open('log', 'w') {|log|
      with_stderr(log) {
        Tb::Cmd.main_git(['-o', o2, '--debug-git-input', g])
      }
    }
    aa = CSV.read(o2)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/,A,foo\n/, row[header.index "files"])
    log = File.read('log')
    assert(!log.empty?)
  end

  def test_warn3
    system("git init -q")
    File.open("foo", "w") {|f| f.puts "bar" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git(['-o', o="o.csv", '--debug-git-output', g='gitlog'])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/,A,foo\n/, row[header.index "files"])
    gresult = File.binread(g)
    FileUtils.rmtree('.git')
    ###
    gresult.sub!(/end-commit/, 'endcommit')
    File.open(g, 'w') {|f| f.print gresult }
    o2 = 'o2.csv'
    File.open('log', 'w') {|log|
      with_stderr(log) {
        Tb::Cmd.main_git(['-o', o2, '--debug-git-input', g])
      }
    }
    aa = CSV.read(o2)
    assert_equal(1, aa.length)
    log = File.read('log')
    assert(!log.empty?)
  end

  def test_binary
    system("git init -q")
    File.open("foo", "w") {|f| f.print "\0\xff" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Tb::Cmd.main_git(['-o', o="o.csv"])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/,,,A,foo\n/, row[header.index "files"])
  end

  def test_subdir
    system("git init -q")
    File.open("foo", "w") {|f| f.print "foo" }
    system("git add foo")
    system("git commit -q -m msg foo")
    Dir.mkdir("bar")
    File.open("bar/baz", "w") {|f| f.print "baz" }
    system("git add bar")
    system("git commit -q -m msg bar")
    Tb::Cmd.main_git(['-o', o="o.csv", "bar"])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_not_match(/foo\n/, row[header.index "files"])
  end

end
