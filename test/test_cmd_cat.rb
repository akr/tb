require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdCat < Test::Unit::TestCase
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
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2
      3,4
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b,c
      5,6
      7,8
    End
    assert_equal(true, Tb::Cmd.main_cat(['-o', o="o.csv", i1, i2]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      1,2
      3,4
      ,5,6
      ,7,8
    End
  end

  def test_numeric
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2
      3,4
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b,c
      5,6
      7,8
    End
    Tb::Cmd.main_cat(['-o', o="o.csv", '-N', i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b
      1,2
      3,4
      b,c
      5,6
      7,8
    End
  end

  def test_extend
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2
      3,4,x
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b,c
      5,6
      7,8,y
    End
    Tb::Cmd.main_cat(['-o', o="o.csv", i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      1,2
      3,4,,x
      ,5,6
      ,7,8,y
    End
  end

  def test_extend_both
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a
      1,x
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b
      2,y
    End
    Tb::Cmd.main_cat(['-o', o="o.csv", i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b
      1,,x
      ,2,y
    End
  end

  def test_field_order
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      1,2,3
      4,5,6
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      c,b,a
      7,8,9
    End
    Tb::Cmd.main_cat(['-o', o="o.csv", i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      1,2,3
      4,5,6
      9,8,7
    End
  end

end
