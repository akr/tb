require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'
begin
  require 'pty'
  require 'io/console'
rescue LoadError
end

class TestTbPager < Test::Unit::TestCase
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

  def with_env(k, v)
    save = ENV[k]
    begin
      ENV[k] = v
      yield
    ensure
      ENV[k] = save
    end
  end

  def with_stdout(io)
    save = STDOUT.dup
    STDOUT.reopen(io)
    begin
      yield
    ensure
      STDOUT.reopen(save)
      save.close
    end
  end

  def reader_thread(io)
    Thread.new {
      r = ''
      loop {
        begin
          r << io.readpartial(4096)
        rescue EOFError, Errno::EIO
          break
        end
      }
      r
    }
  end

  def test_notty
    open("tst", 'w') {|f|
      with_stdout(f) {
        Tb::Pager.open {|pager|
          pager.print "a"
        }
      }
    }
    assert_equal("a", File.read("tst"))
  end

end
