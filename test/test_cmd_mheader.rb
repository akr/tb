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

  def with_stderr(io)
    save = $stderr
    $stderr = io
    begin
      yield
    ensure
      $stderr = save
    end
  end

  def test_basic
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
          ,2000,2000,2001,2001
      name,aaaa,bbbb,aaaa,bbbb
      x,1,2,3,4
      y,5,6,7,8
    End
    Tb::Cmd.main_mheader(['-o', o="o.csv", i])
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
    Tb::Cmd.main_mheader(['-o', o="o.csv", '-c', '2', i])
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
    o = nil
    File.open(log="log", "w") {|logf|
      with_stderr(logf) {
        Tb::Cmd.main_mheader(['-o', o="o.csv", i])
      }
    }
    assert_equal('', File.read(o))
    assert_match(/unique header fields not recognized/, File.read(log))
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
    Tb::Cmd.main_mheader(['-o', o="o.csv", '-c', '2', i1, i2])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a 1,b 2
      3,4
      b,a
      5,6
      7,8
    End
  end

end
