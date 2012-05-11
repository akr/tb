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

  def tar_with_format_option
    return @@tar_with_format_option if defined? @@tar_with_format_option
    commands = %w[tar gtar]
    commands.each {|c|
      msg = IO.popen("exec 2>&1; LC_ALL=C #{c} --help") {|f| f.read }
      if / --format \{(.*)\}/ =~ msg # bsdtar 2.7.0 (FreeBSD 8.2)
        format_desc = $1
        formats = []
        formats << 'ustar' if /\bustar\b/ =~ format_desc
        formats << 'pax' if /\bpax\b/ =~ format_desc
        @@tar_with_format_option = [c, formats]
        return @@tar_with_format_option
      elsif / --format=FORMAT / =~ msg # GNU tar 1.23
        formats = []
        formats << 'gnu' if /\bgnu\b.*\bformat\b/ =~ msg
        formats << 'oldgnu' if /\boldgnu\b.*\bformat\b/ =~ msg
        formats << 'pax' if /\bpax\b.*\bformat\b/ =~ msg
        formats << 'ustar' if /\bustar\b.*\bformat\b/ =~ msg
        formats << 'v7' if /\bv7\b.*\bformat\b/ =~ msg
        @@tar_with_format_option = [c, formats]
        return @@tar_with_format_option
      end
    }
    @@tar_with_format_option = nil
  end

  def with_stdin(io)
    save = $stdin
    $stdin = io
    begin
      yield
    ensure
      $stdin = save
    end
  end

  def test_basic
    open('foo', 'w') {|f| }
    assert(system('tar cf bar.tar foo'))
    Tb::Cmd.main_tar(['-o', o='o.csv', 'bar.tar'])
    assert_match(/,foo,/, File.read(o))
  end

  def test_stdin
    open('foo', 'w') {|f| }
    assert(system('tar cf bar.tar foo'))
    o = nil
    open('bar.tar') {|f|
      with_stdin(f) {
        Tb::Cmd.main_tar(['-o', o='o.csv'])
      }
    }
    assert_match(/,foo,/, File.read(o))
  end

  def test_pipe_stdin
    return unless Process.respond_to? :spawn
    open('foo', 'w') {|f| }
    assert(system('tar cf bar.tar foo'))
    o = nil
    IO.popen('cat bar.tar') {|f|
      with_stdin(f) {
        Tb::Cmd.main_tar(['-o', o='o.csv'])
      }
    }
    assert_match(/,foo,/, File.read(o))
  end

  def test_gzip
    return unless Process.respond_to? :spawn
    open('foo', 'w') {|f| }
    assert(system('tar cf bar.tar foo'))
    assert(system('gzip bar.tar'))
    Tb::Cmd.main_tar(['-o', o='o.csv', 'bar.tar.gz'])
    assert_match(/,foo,/, File.read(o))
  end

  def test_gzip_stdin
    return unless Process.respond_to? :spawn
    open('foo', 'w') {|f| }
    assert(system('tar cf bar.tar foo'))
    assert(system('gzip bar.tar'))
    o = nil
    open('bar.tar.gz') {|f|
      with_stdin(f) {
        Tb::Cmd.main_tar(['-o', o='o.csv'])
      }
    }
    assert_match(/,foo,/, File.read(o))
  end

  def test_gzip_pipe_stdin
    return unless Process.respond_to? :spawn
    open('foo', 'w') {|f| f << "oooo" }
    assert(system('tar cf bar.tar foo'))
    assert(system('gzip bar.tar'))
    o = nil
    IO.popen('cat bar.tar.gz') {|f|
      with_stdin(f) {
        Tb::Cmd.main_tar(['-o', o='o.csv'])
      }
    }
    assert_match(/,foo,/, File.read(o))
  end

  def test_directory
    Dir.mkdir("d")
    open('d/foo', 'w') {|f| f << "hahaha" }
    assert(system('tar cf bar.tar d'))
    Tb::Cmd.main_tar(['-o', o='o.csv', '-l', 'bar.tar'])
    result = File.read(o)
    assert_match(%r{,d/,}, result)
    assert_match(%r{,d/foo,}, result)
  end

  def test_hardlink
    open('foo', 'w') {|f| f << "hahaha" }
    File.link('foo', 'baz')
    assert(system('tar cf bar.tar foo baz'))
    Tb::Cmd.main_tar(['-o', o='o.csv', '-l', 'bar.tar'])
    result = File.read(o)
    assert_match(/,foo,/, result)
    assert_match(/,h/, result)
    assert_match(/,baz,foo,/, result)
  end

  def test_ustar_longpath
    return unless tar_and_formats = tar_with_format_option
    name = 'ABC' + 'a' * 90 + 'DEF/GHI' + 'b' * 90 + 'IJK'
    Dir.mkdir(File.dirname(name))
    open(name, 'w') {|f| }
    %w[ustar gnu oldgnu pax].each {|format|
      next unless tar_and_formats.last.include? format
      tar = tar_and_formats.first
      assert(system("#{tar} cf bar.tar --format=#{format} #{name}"))
      Tb::Cmd.main_tar(['-o', o='o.csv', '-l', 'bar.tar'])
      result = File.read(o)
      assert_equal(2, result.count("\n"), "tar format: #{format}")
      assert_match(/,#{name},/, result)
    }
  end

  def test_ext_longname
    return unless tar_and_formats = tar_with_format_option
    name = 'ABC' + 'a' * 200 + 'XYZ'
    open(name, 'w') {|f| }
    %w[gnu oldgnu pax].each {|format|
      next unless tar_and_formats.last.include? format
      tar = tar_and_formats.first
      assert(system("#{tar} cf bar.tar --format=#{format} #{name}"))
      Tb::Cmd.main_tar(['-o', o='o.csv', '-l', 'bar.tar'])
      result = File.read(o)
      assert_equal(2, result.count("\n"), "tar format: #{format}")
      assert_match(/,#{name},/, result)
    }
  end

  def test_ext_longlink
    return unless tar_and_formats = tar_with_format_option
    link = 'ABC' + 'a' * 200 + 'XYZ'
    File.symlink(link, 'foo')
    %w[gnu oldgnu pax].each {|format|
      next unless tar_and_formats.last.include? format
      tar = tar_and_formats.first
      assert(system("#{tar} cf bar.tar --format=#{format} foo"))
      Tb::Cmd.main_tar(['-o', o='o.csv', '-l', 'bar.tar'])
      result = File.read(o)
      assert_equal(2, result.count("\n"), "tar format: #{format}")
      assert_match(/,#{link},/, result)
    }
  end

  def test_ext_longname_and_longlink
    return unless tar_and_formats = tar_with_format_option
    name = 'ABC' + 'a' * 200 + 'XYZ'
    link = 'ABC' + 'b' * 200 + 'XYZ'
    File.symlink(link, name)
    %w[gnu oldgnu pax].each {|format|
      next unless tar_and_formats.last.include? format
      tar = tar_and_formats.first
      assert(system("#{tar} cf bar.tar --format=#{format} #{name}"))
      Tb::Cmd.main_tar(['-o', o='o.csv', '-l', 'bar.tar'])
      result = File.read(o)
      assert_equal(2, result.count("\n"))
      assert_match(/,#{name},/, result)
      assert_match(/,#{link},/, result)
    }
  end

  def test_mtime
    return unless tar_and_formats = tar_with_format_option
    name = 'foo'
    open(name, 'w') {|f| }
    mtime_from_epoch = 730479600
    mtime = Time.at(mtime_from_epoch)
    File.utime(0, mtime, name)
    %w[v7 ustar oldgnu gnu pax].each {|format|
      next unless tar_and_formats.last.include? format
      tar = tar_and_formats.first
      assert(system("#{tar} cf bar.tar --format=#{format} #{name}"))
      Tb::Cmd.main_tar(['-o', o='o.csv', '-l', 'bar.tar'])
      result = File.read(o)
      assert_equal(2, result.count("\n"), "tar format: #{format}")
      assert_match(/,#{Regexp.escape mtime.iso8601(9)},/, result, "tar format: #{format}")
    }
  end

  def test_atime
    return unless tar_and_formats = tar_with_format_option
    name = 'foo'
    open(name, 'w') {|f| }
    atime_from_epoch = 730479600
    atime = Time.at(atime_from_epoch)
    File.utime(atime, 0, name)
    %w[pax].each {|format|
      next unless tar_and_formats.last.include? format
      tar = tar_and_formats.first
      assert(system("#{tar} cf bar.tar --format=#{format} #{name}"))
      Tb::Cmd.main_tar(['-o', o='o.csv', '-l', 'bar.tar'])
      result = File.read(o)
      assert_equal(2, result.count("\n"), "tar format: #{format}")
      assert_match(/,#{Regexp.escape atime.iso8601(9)},/, result, "tar format: #{format}")
    }
  end

  def test_mtime_subsec
    return unless tar_and_formats = tar_with_format_option
    name = 'foo'
    open(name, 'w') {|f| }
    mtime_from_epoch = 730479600
    mtime = Time.at(mtime_from_epoch, 100000)
    File.utime(0, mtime, name)
    return if File.stat(name).mtime.usec != 100000
    %w[pax].each {|format|
      next unless tar_and_formats.last.include? format
      tar = tar_and_formats.first
      assert(system("#{tar} cf bar.tar --format=#{format} #{name}"))
      Tb::Cmd.main_tar(['-o', o='o.csv', '-l', 'bar.tar'])
      result = File.read(o)
      assert_equal(2, result.count("\n"), "tar format: #{format}")
      assert_match(/,#{Regexp.escape mtime.iso8601(9)},/, result, "tar format: #{format}")
    }
  end

  def test_atime_subsec
    return unless tar_and_formats = tar_with_format_option
    name = 'foo'
    open(name, 'w') {|f| }
    atime_from_epoch = 730479600
    atime = Time.at(atime_from_epoch, 100000)
    File.utime(atime, 0, name)
    return if File.stat(name).atime.usec != 100000
    %w[pax].each {|format|
      next unless tar_and_formats.last.include? format
      tar = tar_and_formats.first
      assert(system("#{tar} cf bar.tar --format=#{format} #{name}"))
      Tb::Cmd.main_tar(['-o', o='o.csv', '-l', 'bar.tar'])
      result = File.read(o)
      assert_equal(2, result.count("\n"), "tar format: #{format}")
      assert_match(/,#{Regexp.escape atime.iso8601(9)},/, result, "tar format: #{format}")
    }
  end

  def test_hash_short
    str = 'bar'
    open('foo', 'w') {|f| f.print str }
    assert(system('tar cf foo.tar foo'))
    %w[MD5 SHA1 SHA256 SHA384 SHA512].each {|cname|
      alg = cname.downcase
      Tb::Cmd.main_tar(['-o', o='o.csv', "--hash=#{alg}", 'foo.tar'])
      result = File.read(o)
      assert_equal(2, result.count("\n"), "hash algorithm: #{alg}")
      assert_match(/,#{Regexp.escape Digest.const_get(cname).hexdigest(str)}$/, result, "hash algorithm: #{alg}")
    }
  end

  def test_hash_long
    str = 'bx' * 8000
    open('foo', 'w') {|f| f.print str }
    assert(system('tar cf foo.tar foo'))
    %w[MD5 SHA1 SHA256 SHA384 SHA512].each {|cname|
      alg = cname.downcase
      Tb::Cmd.main_tar(['-o', o='o.csv', "--hash=#{alg}", 'foo.tar'])
      result = File.read(o)
      assert_equal(2, result.count("\n"), "hash algorithm: #{alg}")
      assert_match(/,#{Regexp.escape Digest.const_get(cname).hexdigest(str)}$/, result, "hash algorithm: #{alg}")
    }
  end

end
