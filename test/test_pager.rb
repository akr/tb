require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

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

  def test_printf
    open("tst", 'w') {|f|
      with_stdout(f) {
        Tb::Pager.open {|pager|
          pager.printf "%x", 255
        }
      }
    }
    assert_equal("ff", File.read("tst"))
  end

  def test_putc_int
    open("tst", 'w') {|f|
      with_stdout(f) {
        Tb::Pager.open {|pager|
          pager.putc 33
        }
      }
    }
    assert_equal("!", File.read("tst"))
  end

  def test_putc_str
    open("tst", 'w') {|f|
      with_stdout(f) {
        Tb::Pager.open {|pager|
          pager.putc "a"
        }
      }
    }
    assert_equal("a", File.read("tst"))
  end

  def test_puts_noarg
    open("tst", 'w') {|f|
      with_stdout(f) {
        Tb::Pager.open {|pager|
          pager.puts
        }
      }
    }
    assert_equal("\n", File.read("tst"))
  end

  def test_puts
    open("tst", 'w') {|f|
      with_stdout(f) {
        Tb::Pager.open {|pager|
          pager.puts "foo"
        }
      }
    }
    assert_equal("foo\n", File.read("tst"))
  end

  def test_write_nonblock
    open("tst", 'w') {|f|
      with_stdout(f) {
        Tb::Pager.open {|pager|
          pager.write_nonblock "foo"
        }
      }
    }
    assert_equal("foo", File.read("tst"))
  end

  def test_flush
    open("tst", 'w') {|f|
      with_stdout(f) {
        Tb::Pager.open {|pager|
          pager.write "foo"
          pager.flush
        }
      }
    }
    assert_equal("foo", File.read("tst"))
  end

end
