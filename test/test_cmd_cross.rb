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
    assert_equal(true, Tb::Cmd.main_cross(['-o', o="o.csv", 'name', 'year', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      name,aaaa,bbbb,cccc
      year,count,count,count
      2000,1,1,
      2001,,1,
      2002,,,1
    End
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

end
