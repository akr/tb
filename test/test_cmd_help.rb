require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdHelp < Test::Unit::TestCase
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

  def with_stderr(io)
    save = STDERR.dup
    STDERR.reopen(io)
    begin
      yield
    ensure
      STDERR.reopen(save)
      save.close
    end
  end

  def with_pipe
    r, w = IO.pipe
    begin
      yield r, w
    ensure
      r.close if !r.closed?
      w.close if !w.closed?
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

  def assert_exit_success(comanndline_words)
    exc = assert_raise(SystemExit) { Tb::Cmd.main(comanndline_words)  }
    assert(exc.success?)
  end

  def assert_exit_fail(comanndline_words)
    exc = assert_raise(SystemExit) { Tb::Cmd.main(comanndline_words)  }
    assert(!exc.success?)
  end

  def test_noarg
    with_pipe {|r, w|
      th = reader_thread(r)
      with_stdout(w) {
        Tb::Cmd.main([])
      }
      w.close
      msg = th.value
      r.close
      assert_match(/Usage:/, msg)
      assert_match(/ tb csv /, msg)
      assert_match(/ tb select /, msg)
    }
  end

  def test_h
    assert_equal(true, Tb::Cmd.main(['-h', '-o', o="msg"]))
    msg = File.read(o)
    assert_match(/Usage:/, msg)
    assert_match(/ tb csv /, msg)
    assert_match(/ tb select /, msg)
  end

  def test_ohelp
    assert_equal(true, Tb::Cmd.main(['--help', '-o', o="msg"]))
    msg = File.read(o)
    assert_match(/Usage:/, msg)
    assert_match(/ tb csv /, msg)
    assert_match(/ tb select /, msg)
  end

  def test_help
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg"]))
    msg = File.read(o)
    assert_match(/Usage:/, msg)
    assert_match(/ tb csv /, msg)
    assert_match(/ tb select /, msg)
  end

  def test_help_h
    assert_exit_success(['help', '-o', o="msg", '-h'])
    msg = File.read(o)
    assert_match(/Usage: tb help/, msg)
    assert_no_match(/Example:/, msg)
  end

  def test_help_hh
    assert_exit_success(['help', '-o', o="msg", '-hh'])
    msg = File.read(o)
    assert_match(/Usage: tb help/, msg)
    assert_match(/Example:/, msg)
  end

  def test_help_help
    assert_exit_success(['help', '-o', o="msg", 'help'])
    msg = File.read(o)
    assert_match(/Usage: tb help/, msg)
    assert_no_match(/Example:/, msg)
  end

  def test_help_h_help
    assert_exit_success(['help', '-o', o="msg", '-h', 'help'])
    msg = File.read(o)
    assert_match(/Usage: tb help/, msg)
    assert_match(/Example:/, msg)
  end

  def test_cat_h
    assert_exit_success(['cat', '-o', o="msg", '-h'])
    msg = File.read(o)
    assert_match(/tb cat /, msg)
    assert_no_match(/Example:/, msg)
  end

  def test_cat_hh
    assert_exit_success(['cat', '-o', o="msg", '-hh'])
    msg = File.read(o)
    assert_match(/tb cat /, msg)
    assert_match(/Example:/, msg)
  end

  def test_help_cat
    assert_exit_success(['help', '-o', o="msg", 'cat'])
    msg = File.read(o)
    assert_match(/tb cat /, msg)
    assert_no_match(/Example:/, msg)
  end

  def test_help_h_cat
    assert_exit_success(['help', '-o', o="msg", '-h', 'cat'])
    msg = File.read(o)
    assert_match(/tb cat /, msg)
    assert_match(/Example:/, msg)
  end

  def test_help_unexpected_subcommand1
    File.open("log", "w") {|log|
      with_stderr(log) {
        assert_exit_fail(['help', '-o', "msg", 'foo'])
      }
    }
    assert_match(/unexpected subcommand/, File.read("log"))
  end

  def test_help_unexpected_subcommand2
    exc = assert_raise(SystemExit) { Tb::Cmd.main_help(['foo']) }
    assert(!exc.success?)
    assert_match(/unexpected subcommand/, exc.message)
  end

  def test_top_unexpected_subcommand
    exc = assert_raise(SystemExit) { Tb::Cmd.main_body(['foo']) }
    assert(!exc.success?)
    assert_match(/unexpected subcommand/, exc.message)
  end

end
