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
    assert_equal(0, Tb::Func.smart_cmp_value(0) <=> Tb::Func.smart_cmp_value(0))
    assert_equal(1, Tb::Func.smart_cmp_value(10) <=> Tb::Func.smart_cmp_value(0))
    assert_equal(-1, Tb::Func.smart_cmp_value(-10) <=> Tb::Func.smart_cmp_value(0))
    assert_equal(0, Tb::Func.smart_cmp_value("a") <=> Tb::Func.smart_cmp_value("a"))
    assert_equal(1, Tb::Func.smart_cmp_value("z") <=> Tb::Func.smart_cmp_value("a"))
    assert_equal(-1, Tb::Func.smart_cmp_value("a") <=> Tb::Func.smart_cmp_value("b"))
    assert_equal(1, Tb::Func.smart_cmp_value("08") <=> Tb::Func.smart_cmp_value("7"))
    assert_raise(ArgumentError) { Tb::Func.smart_cmp_value(Object.new) }
  end

  def test_parse_aggregator_spec2
    assert_raise(ArgumentError) { parse_aggregator_spec2("foo") }
  end

  def test_with_output_preserve_mtime
    Dir.mktmpdir {|d|
      fn = "#{d}/a"
      File.open(fn, "w") {|f| f.print "foo" }
      t0 = Time.utc(2000)
      File.utime(t0, t0, fn)
      t1 = File.stat(fn).mtime
      with_output(fn) {|f|
        f.print "foo"
      }
      t2 = File.stat(fn).mtime
      assert_equal(t1, t2)
    }
  end

end
