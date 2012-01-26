require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdCross < Test::Unit::TestCase
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
      name,year,observ
      aaaa,2000,1
      bbbb,2001,3
      bbbb,2000,4
      cccc,2002,5
    End
    Tb::Cmd.main_cross(['-o', o="o.csv", 'name', 'year', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      name,aaaa,bbbb,cccc
      year,count,count,count
      2000,1,1,
      2001,,1,
      2002,,,1
    End
  end

  def test_no_hkey_fields
    exc = assert_raise(SystemExit) { Tb::Cmd.main_cross([]) }
    assert(!exc.success?)
  end

  def test_no_vkey_fields
    exc = assert_raise(SystemExit) { Tb::Cmd.main_cross(['hk']) }
    assert(!exc.success?)
  end

  def test_field_not_found
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      name,year,observ
      aaaa,2000,1
      bbbb,2001,3
    End
    exc = assert_raise(SystemExit) { Tb::Cmd.main_cross(['-o', "o.csv", 'foo', 'year', i]) }
    assert(!exc.success?)
    exc = assert_raise(SystemExit) { Tb::Cmd.main_cross(['-o', "o.csv", 'name', 'bar', i]) }
    assert(!exc.success?)
  end

  def test_compact
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      name,year,observ
      aaaa,2000,1
      bbbb,2001,3
      bbbb,2000,4
      cccc,2002,5
    End
    Tb::Cmd.main_cross(['-o', o="o.csv", 'name', 'year', '-c', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      year,aaaa,bbbb,cccc
      2000,1,1,
      2001,,1,
      2002,,,1
    End
  end

  def test_sum
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      name,year,observ
      aaaa,2000,1
      bbbb,2001,3
      bbbb,2000,4
      cccc,2002,5
      aaaa,2000,2
    End
    Tb::Cmd.main_cross(['-o', o="o.csv", 'name', 'year', '-a', 'sum(observ)', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      name,aaaa,bbbb,cccc
      year,sum(observ),sum(observ),sum(observ)
      2000,3,4,
      2001,,3,
      2002,,,5
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
    Tb::Cmd.main_cross(['-o', o="o.csv", 'a', 'b', i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,1,3,6,8
      b,count,count,count,count
      2,1,,,
      4,,1,,
      5,,,1,
      7,,,,1
    End
  end

  def test_invalid_aggregator
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b
      1,2
      3,4
    End
    exc = assert_raise(SystemExit) { Tb::Cmd.main_cross(['-o', "o.csv", 'a', 'b', '-a', 'foo', i]) }
    assert(!exc.success?)
  end
end
