require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdJoin < Test::Unit::TestCase
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
      a,c
      1,a
      3,b
    End
    assert_equal(true, Tb::Cmd.main_join(['-o', o="o.csv", i1, i2]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      1,2,a
      3,4,b
    End
  end

  def test_outer_missing
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2
      3,4
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b,c
      4,5
      6,7
    End
    assert_equal(true, Tb::Cmd.main_join(['-o', o="o.csv", '--outer-missing=z', i1, i2]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      1,2,z
      3,4,5
      z,6,7
    End
  end

  def test_outer_left
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2
      3,4
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b,c
      4,5
      6,7
    End
    assert_equal(true, Tb::Cmd.main_join(['-o', o="o.csv", '--left', i1, i2]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      1,2,
      3,4,5
    End
  end

  def test_outer_right
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2
      3,4
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b,c
      4,5
      6,7
    End
    assert_equal(true, Tb::Cmd.main_join(['-o', o="o.csv", '--right', i1, i2]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      3,4,5
      ,6,7
    End
  end

end
