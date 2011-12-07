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

  def test_list_subcommand
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg"]))
    msg = File.read(o)
    assert_match(/Usage:/, msg)
    assert_match(/ tb csv /, msg)
    assert_match(/ tb select /, msg)
  end

  def test_help_subcommand
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg", 'cat']))
    msg = File.read(o)
    assert_match(/tb cat /, msg)
  end

  def test_subcommand_helpoption
    assert_equal(true, Tb::Cmd.main(['cat', '-o', o="msg", '-h']))
    msg = File.read(o)
    assert_match(/tb cat /, msg)
  end

  def test_help_subcommand_v
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg", '-v', 'cat']))
    msg = File.read(o)
    assert_match(/tb cat /, msg)
    assert_match(/Example:/, msg)
  end

  def test_subcommand_helpoption_v
    assert_equal(true, Tb::Cmd.main(['cat', '-o', o="msg", '-hv']))
    msg = File.read(o)
    assert_match(/tb cat /, msg)
    assert_match(/Example:/, msg)
  end

  def test_unexpected_subcommand
    save = STDERR.dup
    log = File.open("log", "w")
    STDERR.reopen(log)
    log.close
    assert_raise(SystemExit) { Tb::Cmd.main_help(['-o', "msg", 'foo']) }
    STDERR.reopen(save)
    save.close
    assert_match(/unexpected subcommand/, File.read("log"))
  ensure
    save.close if save && !save.closed?
    log.close if log && !log.closed?
  end

  def test_opt_h
    assert_equal(true, Tb::Cmd.main(['-h', '-o', o="msg"]))
    msg = File.read(o)
    assert_match(/Usage:/, msg)
    assert_match(/ tb csv /, msg)
    assert_match(/ tb select /, msg)
  end

end
