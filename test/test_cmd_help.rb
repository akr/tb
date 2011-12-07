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

  def test_help
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg"]))
    msg = File.read(o)                       
    assert_match(/Usage:/, msg)              
    assert_match(/ tb csv /, msg)            
    assert_match(/ tb select /, msg)         
  end                                        
                                             
  def test_help_h                            
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg", '-h']))
    msg = File.read(o)                       
    assert_match(/Usage: tb help/, msg)
    assert_not_match(/Example:/, msg)        
  end                                        
                                             
  def test_help_hh                           
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg", '-hh']))
    msg = File.read(o)                       
    assert_match(/Usage: tb help/, msg)
    assert_match(/Example:/, msg)            
  end                                        
                                             
  def test_help_help                         
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg", 'help']))
    msg = File.read(o)                       
    assert_match(/Usage: tb help/, msg)
    assert_not_match(/Example:/, msg)        
  end                                        
                                             
  def test_help_h_help                       
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg", '-h', 'help']))
    msg = File.read(o)
    assert_match(/Usage: tb help/, msg)
    assert_match(/Example:/, msg)
  end

  def test_cat_h
    assert_equal(true, Tb::Cmd.main(['cat', '-o', o="msg", '-h']))
    msg = File.read(o)
    assert_match(/tb cat /, msg)
    assert_not_match(/Example:/, msg)
  end

  def test_cat_hh
    assert_equal(true, Tb::Cmd.main(['cat', '-o', o="msg", '-hh']))
    msg = File.read(o)
    assert_match(/tb cat /, msg)
    assert_match(/Example:/, msg)
  end

  def test_help_cat
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg", 'cat']))
    msg = File.read(o)                       
    assert_match(/tb cat /, msg)             
    assert_not_match(/Example:/, msg)        
  end                                        
                                             
  def test_help_h_cat                        
    assert_equal(true, Tb::Cmd.main(['help', '-o', o="msg", '-h', 'cat']))
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
