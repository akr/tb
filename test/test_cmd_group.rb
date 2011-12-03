require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdGroup < Test::Unit::TestCase
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
      x,5,6,y
    End
    assert_equal(true, Tb::Cmd.main_group(['-o', o="o.csv", 'b,c', '-a', 'count', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      b,c,count
      1,2,1
      5,6,2
      9,a,1
      d,e,1
    End
  end

  def test_sum
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,4,1
      c,d,5,2.5
      x,5,6,3
    End
    assert_equal(true, Tb::Cmd.main_group(['-o', o="o.csv", 'b', '-a', 'sum(d)', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      b,sum(d)
      1,3
      5,10
      9,1
      d,2.5
    End
  end

  def test_max
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,4,1
      c,d,5,2.5
      x,5,6,3
    End
    assert_equal(true, Tb::Cmd.main_group(['-o', o="o.csv", 'b', '-a', 'max(d)', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      b,max(d)
      1,3
      5,7
      9,1
      d,2.5
    End
  end

  def test_min
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,4,1
      c,d,5,2.5
      x,5,6,3
    End
    assert_equal(true, Tb::Cmd.main_group(['-o', o="o.csv", 'b', '-a', 'min(d)', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      b,min(d)
      1,3
      5,3
      9,1
      d,2.5
    End
  end

  def test_avg
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,4,1
      c,d,5,2.5
      x,5,6,3
    End
    assert_equal(true, Tb::Cmd.main_group(['-o', o="o.csv", 'b', '-a', 'avg(d)', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      b,avg(d)
      1,3.0
      5,5.0
      9,1.0
      d,2.5
    End
  end

  def test_values
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      A,1
      A,2
      B,3
      A,1
    End
    assert_equal(true, Tb::Cmd.main_group(['-o', o="o.csv", 'a', '-a', 'values(b)', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,values(b)
      A,"1,2,1"
      B,3
    End
  end

  def test_uniquevalues
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      A,1
      A,2
      B,3
      A,1
    End
    assert_equal(true, Tb::Cmd.main_group(['-o', o="o.csv", 'a', '-a', 'uniquevalues(b)', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,uniquevalues(b)
      A,"1,2"
      B,3
    End
  end

end
