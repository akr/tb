require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdTarTvf < Test::Unit::TestCase
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

  def gnu_tar
    return @@gnu_tar if defined? @@gnu_tar
    commands = %w[gtar tar]
    commands.each {|c|
      msg = IO.popen("exec 2>&1; LC_ALL=C #{c} --help") {|f| f.read }
      if /GNU/ =~ msg
        @@gnu_tar = c
        return @@gnu_tar
      end
    }
    @@gnu_tar = nil
  end

  def test_basic
    open('foo', 'w') {|f| }
    assert(system('tar cf bar.tar foo'))
    Tb::Cmd.main_tar_tvf(['-o', o='o.csv', 'bar.tar'])
    assert_match(/,foo,/, File.read(o))
  end

  def test_gnu_longname
    return unless gtar = gnu_tar
    name = 'ABC' + 'a' * 200 + 'XYZ'
    open(name, 'w') {|f| }
    assert(system("#{gtar} cf bar.tar --format=gnu #{name}"))
    Tb::Cmd.main_tar_tvf(['-o', o='o.csv', '-l', 'bar.tar'])
    result = File.read(o)
    assert_equal(2, result.count("\n"))
    assert_match(/,#{name},/, result)
  end

  def test_gnu_longlink
    return unless gtar = gnu_tar
    link = 'ABC' + 'a' * 200 + 'XYZ'
    File.symlink(link, 'foo')
    assert(system("#{gtar} cf bar.tar --format=gnu foo"))
    Tb::Cmd.main_tar_tvf(['-o', o='o.csv', '-l', 'bar.tar'])
    result = File.read(o)
    assert_equal(2, result.count("\n"))
    assert_match(/,#{link},/, result)
  end

  def test_gnu_longname_and_longlink
    return unless gtar = gnu_tar
    name = 'ABC' + 'a' * 200 + 'XYZ'
    link = 'ABC' + 'b' * 200 + 'XYZ'
    File.symlink(link, name)
    assert(system("#{gtar} cf bar.tar --format=gnu #{name}"))
    Tb::Cmd.main_tar_tvf(['-o', o='o.csv', '-l', 'bar.tar'])
    result = File.read(o)
    assert_equal(2, result.count("\n"))
    assert_match(/,#{name},/, result)
    assert_match(/,#{link},/, result)
  end

end
