require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'
begin
  require 'pty'
  require 'io/console'
rescue LoadError
end

class TestTbCmdTTY < Test::Unit::TestCase
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

  def test_ttyout
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c
      0,1,2
      4,5,6
    End
    save_pager = ENV['PAGER']
    ENV['PAGER'] = 'cat'
    m, s = PTY.open
    s.raw!
    th = Thread.new {
      r = ''
      loop {
        begin
          r << m.readpartial(4096)
        rescue EOFError, Errno::EIO
          break
        end
      }
      r
    }
    save = STDOUT.dup
    STDOUT.reopen(s)
    s.close
    main_result = Tb::Cmd.main_csv([i])
    STDOUT.reopen(save)
    save.close
    result = th.value
    assert_equal(true, main_result)
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), result)
      a,b,c
      0,1,2
      4,5,6
    End
  ensure
    ENV['PAGER'] = save_pager
    m.close if m && !m.closed?
    s.close if s && !s.closed?
    save.close if save && !save.closed?
  end

end if defined?(PTY) && defined?(PTY.open)
