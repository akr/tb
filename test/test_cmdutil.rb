require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdUtil < Test::Unit::TestCase
  def setup
    Tb::Cmd.reset_option
    #@curdir = Dir.pwd
    #@tmpdir = Dir.mktmpdir
    #Dir.chdir @tmpdir
  end
  def teardown
    Tb::Cmd.reset_option
    #Dir.chdir @curdir
    #FileUtils.rmtree @tmpdir
  end

  def test_def_vhelp
    verbose_help = Tb::Cmd.instance_variable_get(:@verbose_help)
    verbose_help['foo'] = 'bar'
    begin
      assert_raise(ArgumentError) { Tb::Cmd.def_vhelp('foo', 'baz') }
    ensure
      verbose_help.delete 'foo'
    end
  end

  def test_smart_cmp_value
    assert_equal(0, smart_cmp_value(0) <=> smart_cmp_value(0))
    assert_equal(1, smart_cmp_value(10) <=> smart_cmp_value(0))
    assert_equal(-1, smart_cmp_value(-10) <=> smart_cmp_value(0))
    assert_equal(0, smart_cmp_value("a") <=> smart_cmp_value("a"))
    assert_equal(1, smart_cmp_value("z") <=> smart_cmp_value("a"))
    assert_equal(-1, smart_cmp_value("a") <=> smart_cmp_value("b"))
    assert_raise(ArgumentError) { smart_cmp_value(Object.new) }
  end

  def test_conv_to_numeric
    assert_raise(ArgumentError) { conv_to_numeric("foo") }
  end

end
