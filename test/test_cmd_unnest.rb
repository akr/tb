require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdUnnest < Test::Unit::TestCase
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
      foo,"b1,b2
      1,2
      3,4
      ",baz
      qux,"b1,b2
      5,6
      ",quuux
    End
    Tb::Cmd.main_unnest(['-o', o="o.csv", 'b', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b1,b2,c
      foo,1,2,baz
      foo,3,4,baz
      qux,5,6,quuux
    End
  end

  def test_opt_outer1
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      foo,"b1,b2
      1,2
      ",baz
      f,"b1,b2
      ",g
      qux,,quuux
    End
    Tb::Cmd.main_unnest(['-o', o="o.csv", '--outer', 'b', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b1,b2,c
      foo,1,2,baz
      f,,,g
      qux,,,quuux
    End
  end

  def test_opt_no_outer
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      foo,"b1,b2
      1,2
      ",baz
      f,"b1,b2
      ",g
      qux,,quuux
    End
    Tb::Cmd.main_unnest(['-o', o="o.csv", 'b', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b1,b2,c
      foo,1,2,baz
    End
  end

  def test_no_target_field
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      foo,"b1,b2
      1,2
      3,4
      ",baz
      qux,"b1,b2
      5,6
      ",quuux
    End
    exc = assert_raise(SystemExit) {  Tb::Cmd.main_unnest(['-o', o="o.csv", 'bb', i]) }
    assert(!exc.success?)

  end

end
