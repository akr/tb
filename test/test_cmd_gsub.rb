require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdGsub < Test::Unit::TestCase
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
      foo,bar,baz
      qux,quuux
    End
    Tb::Cmd.main_gsub(['-o', o="o.csv", '[au]', 'YY', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      foo,bYYr,bYYz
      qYYx,qYYYYYYx
    End
  end

  def test_no_regexp
    exc = assert_raise(SystemExit) { Tb::Cmd.main_gsub([]) }
    assert(!exc.success?)
  end

  def test_no_subst
    exc = assert_raise(SystemExit) { Tb::Cmd.main_gsub(['foo']) }
    assert(!exc.success?)
  end

  def test_opt_e
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      foo,bar,baz
      qux,quuux
    End
    Tb::Cmd.main_gsub(['-o', o="o.csv", '-e', '[au]', 'YY', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      foo,bYYr,bYYz
      qYYx,qYYYYYYx
    End
  end

  def test_opt_f
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      foo,bar,baz
      qux,quuux
    End
    Tb::Cmd.main_gsub(['-o', o="o.csv", '-f', 'b', '[au]', 'YY', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      foo,bYYr,baz
      qux,qYYYYYYx
    End
  end

  def test_opt_f_extend
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      foo,bar,baz
    End
    Tb::Cmd.main_gsub(['-o', o="o.csv", '-f', '1', 'baz', 'Y', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b
      foo,bar,Y
    End
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
    Tb::Cmd.main_gsub(['-o', o="o.csv", '[46]', 'z', i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b
      1,2
      3,z
      z,5
      8,7
    End
  end

end
