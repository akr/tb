require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdRename < Test::Unit::TestCase
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
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    assert_equal(true, Tb::Cmd.main_rename(['-o', o="o.csv", 'b,x,c,b', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,x,b,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
  end

  def test_empty
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    assert_equal(true, Tb::Cmd.main_rename(['-o', o="o.csv", '', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
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
    assert_equal(true, Tb::Cmd.main_rename(['-o', o="o.csv", 'a,c', i1, i2]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      c,b
      1,2
      3,4
      6,5
      8,7
    End
  end

end
