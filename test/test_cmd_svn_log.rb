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
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/baz/, row[header.index "msg"])
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
    aa = CSV.read(o)
    assert_equal(3, aa.length)
    header, *rows = aa
    rows = rows.sort_by {|rec| rows[header.index 'path'] }
    rows.each {|row|
      assert_match(/baz/, row[header.index "msg"])
    }
    assert_match(/foo/, rows[0][header.index "path"])
    assert_match(/hoge/, rows[1][header.index "path"])
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
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/baz/, row[header.index "msg"])
    ###
    system("svn log --xml > log.xml")
    FileUtils.rmtree('.svn')
    Tb::Cmd.main_svn(['-o', o="o.csv", '--svn-log-xml=log.xml'])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_match(/baz/, row[header.index "msg"])
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
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_equal('(no author)', row[header.index "author"])
    assert_equal('(no date)', row[header.index "date"])
    assert_equal('', row[header.index "msg"])
  end
end
