require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdSvnLog < Test::Unit::TestCase
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
    system("svnadmin create repo")
    system("svn co -q file://#{@tmpdir}/repo .")
    File.open("foo", "w") {|f| f.puts "bar" }
    File.open("hoge", "w") {|f| f.puts "moge" }
    system("svn add -q foo hoge")
    system("svn commit -q -m baz foo hoge")
    system("svn update -q") # update the revision of the directory.
    Tb::Cmd.main_svn(['-o', o="o.csv"])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/baz/, tb.get_record(0)["msg"])
  end

  def test_verbose
    system("svnadmin create repo")
    system("svn co -q file://#{@tmpdir}/repo .")
    File.open("foo", "w") {|f| f.puts "bar" }
    File.open("hoge", "w") {|f| f.puts "moge" }
    system("svn add -q foo hoge")
    system("svn commit -q -m baz foo hoge")
    system("svn update -q") # update the revision of the directory.
    Tb::Cmd.main_svn(['-o', o="o.csv", '--', '-v'])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(2, tb.size)
    recs = [tb.get_record(0), tb.get_record(1)]
    recs = recs.sort_by {|rec| rec['path'] }
    recs.each {|rec|
      assert_match(/baz/, rec["msg"])
    }
    assert_match(/foo/, recs[0]["path"])
    assert_match(/hoge/, recs[1]["path"])
  end

  def test_log_xml
    system("svnadmin create repo")
    system("svn co -q file://#{@tmpdir}/repo .")
    File.open("foo", "w") {|f| f.puts "bar" }
    File.open("hoge", "w") {|f| f.puts "moge" }
    system("svn add -q foo hoge")
    system("svn commit -q -m baz foo hoge")
    system("svn update -q") # update the revision of the directory.
    ###
    Tb::Cmd.main_svn(['-o', o="o.csv"])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/baz/, tb.get_record(0)["msg"])
    ###
    system("svn log --xml > log.xml")
    FileUtils.rmtree('.svn')
    Tb::Cmd.main_svn(['-o', o="o.csv", '--svn-log-xml=log.xml'])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_match(/baz/, tb.get_record(0)["msg"])
  end

  def test_no_props
    system("svnadmin create repo")
    File.open("repo/hooks/pre-revprop-change", "w", 0755) {|f| f.print "#!/bin/sh\nexit 0\0" }
    system("svn co -q file://#{@tmpdir}/repo .")
    File.open("foo", "w") {|f| f.puts "bar" }
    system("svn add -q foo")
    system("svn commit -q -m baz foo")
    system("svn update -q") # update the revision of the directory.
    system("svn propdel -q svn:author --revprop -r 1 .")
    system("svn propdel -q svn:date --revprop -r 1 .")
    system("svn propdel -q svn:log --revprop -r 1 .")
    ###
    Tb::Cmd.main_svn(['-o', o="o.csv"])
    result = File.read(o)
    tb = Tb.parse_csv(result)
    assert_equal(1, tb.size)
    assert_equal('(no author)', tb.get_record(0)["author"])
    assert_equal('(no date)', tb.get_record(0)["date"])
    assert_equal('', tb.get_record(0)["msg"])
  end
end
