require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdSort < Test::Unit::TestCase
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
      a,b
      1,4
      0,3
      3,2
    End
    assert_equal(true, Tb::Cmd.main_sort(['-o', o="o.csv", i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b
      0,3
      1,4
      3,2
    End
  end

  def test_numeric
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,4
      0,3
      3,2
    End
    assert_equal(true, Tb::Cmd.main_sort(['-o', o="o.csv", '-N', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      0,3
      1,4
      3,2
      a,b
    End
  end

  def test_opt_f
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,4
      0,3
      3,2
    End
    assert_equal(true, Tb::Cmd.main_sort(['-o', o="o.csv", '-f', 'b', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b
      3,2
      0,3
      1,4
    End
  end

  def test_cmp
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      10,a20b0,11
      1,2e1,3
      4,,6
      7,8,9
    End
    assert_equal(true, Tb::Cmd.main_sort(['-o', o="o.csv", '-f', 'b', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      4,,6
      7,8,9
      1,2e1,3
      10,a20b0,11
    End
  end

end
