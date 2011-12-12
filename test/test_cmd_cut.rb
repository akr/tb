require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdSelect < Test::Unit::TestCase
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
    Tb::Cmd.main_cut(['-o', o="o.csv", 'b,d', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      b,d
      1,3
      5,7
      9,b
      d,f
    End
  end

  def test_no_cut_fields
    exc = assert_raise(SystemExit) { Tb::Cmd.main_cut([]) }
    assert(!exc.success?)
  end

  def test_opt_v
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    Tb::Cmd.main_cut(['-o', o="o.csv", '-v', 'b,d', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,c
      0,2
      4,6
      8,a
      c,e
    End
  end

  def test_extend
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      0,1,2,3
    End
    Tb::Cmd.main_cut(['-o', o="o.csv", 'a,2,1', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,2,1
      0,3,2
    End
  end

  def test_unextendable
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      0,1,2,3
    End
    assert_raise(ArgumentError) { Tb::Cmd.main_cut(['-o', "o.csv", '0', i]) }
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
    Tb::Cmd.main_cut(['-o', o="o.csv", 'a', i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a
      1
      3
      6
      8
    End
  end

end
