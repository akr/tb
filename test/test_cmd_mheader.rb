require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdMheader < Test::Unit::TestCase
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
          ,2000,2000,2001,2001
      name,aaaa,bbbb,aaaa,bbbb
      x,1,2,3,4
      y,5,6,7,8
    End
    assert_equal(true, Tb::Cmd.main_mheader(['-o', o="o.csv", i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      name,2000 aaaa,2000 bbbb,2001 aaaa,2001 bbbb
      x,1,2,3,4
      y,5,6,7,8
    End
  end

  def test_opt_c
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      1,2,3
      4,5,6
    End
    assert_equal(true, Tb::Cmd.main_mheader(['-o', o="o.csv", '-c', '2', i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a 1,b 2,c 3
      4,5,6
    End
  end

  def test_no_unique_header
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,a
      1,1
    End
    save = STDERR.dup
    log = File.open(log="log", "w")
    STDERR.reopen(log)
    log.close
    assert_equal(true, Tb::Cmd.main_mheader(['-o', o="o.csv", i]))
    STDERR.reopen(save)
    save.close
    assert_equal('', File.read(o))
    assert_match(/no header found/, File.read(log))
  end

end
