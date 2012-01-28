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
    Tb::Cmd.main_join(['-o', o="o.csv", i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      1,2,a
      3,4,b
    End
  end

  def test_noarg
    exc = assert_raise(SystemExit) { Tb::Cmd.main_join(['-o', "o.csv"]) }
    assert(!exc.success?)
  end

  def test_onearg
    exc = assert_raise(SystemExit) { Tb::Cmd.main_join(['-o', "o.csv", 'foo.csv']) }
    assert(!exc.success?)
  end

  def test_outer
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
    Tb::Cmd.main_join(['-o', o="o.csv", '--outer', i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      1,2,
      3,4,5
      ,6,7
    End
  end

  def test_outer2
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      b,c
      4,5
      6,7
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2
      3,4
    End
    Tb::Cmd.main_join(['-o', o="o.csv", '--outer', i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      b,c,a
      2,,1
      4,5,3
      6,7,
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
    Tb::Cmd.main_join(['-o', o="o.csv", '--outer-missing=z', i1, i2])
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
    Tb::Cmd.main_join(['-o', o="o.csv", '--left', i1, i2])
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
    Tb::Cmd.main_join(['-o', o="o.csv", '--right', i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c
      3,4,5
      ,6,7
    End
  end

  def test_3file_inner
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
    File.open(i3="i3.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,d
      1,x
      3,z
    End
    Tb::Cmd.main_join(['-o', o="o.csv", i1, i2, i3])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c,d
      1,2,a,x
      3,4,b,z
    End
  end

  def test_3file_left
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,A
      2,B
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,c
      1,C
      3,D
    End
    File.open(i3="i3.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,d
      2,E
      4,F
    End
    Tb::Cmd.main_join(['-o', o="o.csv", '--left', i1, i2, i3])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c,d
      1,A,C,
      2,B,,E
    End
  end

  def test_3file_right
    File.open(i1="i1.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,A
      2,B
    End
    File.open(i2="i2.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,c
      1,C
      3,D
    End
    File.open(i3="i3.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,d
      2,E
      3,F
    End
    Tb::Cmd.main_join(['-o', o="o.csv", '--right', i1, i2, i3])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c,d
      2,,,E
      3,,D,F
    End
  end

end
