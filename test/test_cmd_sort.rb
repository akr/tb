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
    Tb::Cmd.main_sort(['-o', o="o.csv", i])
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
    Tb::Cmd.main_sort(['-o', o="o.csv", '-N', i])
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
    Tb::Cmd.main_sort(['-o', o="o.csv", '-f', 'b', i])
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
    Tb::Cmd.main_sort(['-o', o="o.csv", '-f', 'b', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      4,,6
      7,8,9
      1,2e1,3
      10,a20b0,11
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
      5,0
      7,8
    End
    Tb::Cmd.main_sort(['-o', o="o.csv", i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b
      0,5
      1,2
      3,4
      8,7
    End
  end

end
