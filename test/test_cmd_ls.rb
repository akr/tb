require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdLs < Test::Unit::TestCase
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

  def with_stderr(io)
    save = $stderr
    $stderr = io
    begin
      yield
    ensure
      $stderr = save
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

  def test_basic
    Dir.mkdir("d")
    File.open("d/a", "w") {}
    Tb::Cmd.main_ls(['-o', o="o.csv", "d"])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      filename
      d/a
    End
  end

  def test_opt_l_single
    File.open("a", "w") {}
    File.chmod(0754, "a")
    Tb::Cmd.main_ls(['-o', o="o.csv", '-l', 'a'])
    tb = Tb.load_csv(o)
    assert_equal(1, tb.size)
    assert_equal(%w[filemode nlink user group size mtime filename symlink], tb.list_fields)
    rec = tb.get_record(0)
    assert_equal("-rwxr-xr--", rec["filemode"])
    assert_equal("1", rec["nlink"])
    assert_match(/\A\d+\z/, rec["size"])
    assert_match(/\A\d+-\d\d-\d\dT\d\d:\d\d:\d\d/, rec["mtime"])
    assert_equal("a", rec["filename"])
    assert_equal(nil, rec["symlink"])
  end

  def test_opt_l
    Dir.mkdir("d")
    File.open("d/a", "w") {}
    Dir.mkdir("d/d2")
    Tb::Cmd.main_ls(['-o', o="o.csv", '-l', 'd'])
    tb = Tb.load_csv(o)
    assert_equal(2, tb.size)
    assert_equal("d/a", tb.get_record(0)["filename"])
    assert_equal("d/d2", tb.get_record(1)["filename"])
  end

  def test_opt_ll_single
    File.open("a", "w") {}
    File.chmod(0754, "a")
    Tb::Cmd.main_ls(['-o', o="o.csv", '-ll', 'a'])
    tb = Tb.load_csv(o)
    assert_equal(1, tb.size)
    assert_equal(%w[dev ino mode filemode nlink uid user gid group rdev size blksize blocks atime mtime ctime filename symlink], tb.list_fields)
    rec = tb.get_record(0)
    assert_match(/\A0x[0-9a-f]+\z/, rec["dev"])
    assert_match(/\A\d+\z/, rec["ino"])
    assert_match(/\A0[0-7]+\z/, rec["mode"])
    assert_equal("-rwxr-xr--", rec["filemode"])
    assert_equal("1", rec["nlink"])
    assert_match(/\A\d+\z/, rec["uid"])
    assert_match(/\A\d+\z/, rec["gid"])
    assert_match(/\A0x[0-9a-f]+\z/, rec["rdev"])
    assert_match(/\A\d+\z/, rec["size"])
    assert_match(/\A\d+\z/, rec["blksize"])
    assert_match(/\A\d+\z/, rec["blocks"])
    assert_match(/\A\d+-\d\d-\d\dT\d\d:\d\d:\d\d/, rec["atime"])
    assert_match(/\A\d+-\d\d-\d\dT\d\d:\d\d:\d\d/, rec["mtime"])
    assert_match(/\A\d+-\d\d-\d\dT\d\d:\d\d:\d\d/, rec["ctime"])
    assert_equal("a", rec["filename"])
    assert_equal(nil, rec["symlink"])
  end

  def test_opt_a
    Dir.mkdir("d")
    File.open("d/.foo", "w") {}
    Tb::Cmd.main_ls(['-o', o="o.csv", '-a', 'd'])
    tb = Tb.load_csv(o)
    assert_equal(3, tb.size)
    assert_equal("d", tb.get_record(0)["filename"]) # d/.
    assert_equal(".", tb.get_record(1)["filename"]) # d/..
    assert_equal("d/.foo", tb.get_record(2)["filename"])
  end

  def test_opt_A
    Dir.mkdir("d")
    File.open("d/.foo", "w") {}
    Tb::Cmd.main_ls(['-o', o="o.csv", '-A', 'd'])
    tb = Tb.load_csv(o)
    assert_equal(1, tb.size)
    assert_equal("d/.foo", tb.get_record(0)["filename"])
  end

  def test_opt_R
    Dir.mkdir("d")
    File.open("d/a", "w") {}
    Dir.mkdir("d/d2")
    File.open("d/d2/b", "w") {}
    File.open("d/d2/c", "w") {}
    Tb::Cmd.main_ls(['-o', o="o.csv", '-R', 'd'])
    tb = Tb.load_csv(o)
    assert_equal(4, tb.size)
    assert_equal("d/a", tb.get_record(0)["filename"])
    assert_equal("d/d2", tb.get_record(1)["filename"])
    assert_equal("d/d2/b", tb.get_record(2)["filename"])
    assert_equal("d/d2/c", tb.get_record(3)["filename"])
  end

  def test_opt_Ra
    Dir.mkdir("d")
    File.open("d/a", "w") {}
    Dir.mkdir("d/d2")
    File.open("d/d2/b", "w") {}
    File.open("d/d2/c", "w") {}
    Tb::Cmd.main_ls(['-o', o="o.csv", '-Ra', 'd'])
    tb = Tb.load_csv(o)
    assert_equal(8, tb.size)
    assert_equal("d/.", tb.get_record(0)["filename"])
    assert_equal("d/..", tb.get_record(1)["filename"])
    assert_equal("d/a", tb.get_record(2)["filename"])
    assert_equal("d/d2", tb.get_record(3)["filename"])
    assert_equal("d/d2/.", tb.get_record(4)["filename"])
    assert_equal("d/d2/..", tb.get_record(5)["filename"])
    assert_equal("d/d2/b", tb.get_record(6)["filename"])
    assert_equal("d/d2/c", tb.get_record(7)["filename"])
  end

  def test_symlink
    File.symlink("a", "b")
    Tb::Cmd.main_ls(['-o', o="o.csv", '-l', 'b'])
    tb = Tb.load_csv(o)
    assert_equal(1, tb.size)
    assert_equal("b", tb.get_record(0)["filename"])
    assert_equal("a", tb.get_record(0)["symlink"])
  end

  def test_not_found
    File.open("log", "w") {|log|
      with_stderr(log) {
        exc = assert_raise(SystemExit) { Tb::Cmd.main_ls(['-o', "o.csv", '-l', 'a']) }
        assert(!exc.success?)
      }
    }
  end

  def test_dir_entries_fail
    Dir.mkdir("d")
    begin
      File.chmod(0, "d")
      File.open("log", "w") {|log|
        with_stderr(log) {
          exc = assert_raise(SystemExit) { Tb::Cmd.main_ls(['-o', "o.csv", '-l', 'd']) }
          assert(!exc.success?)
        }
      }
    ensure
      File.chmod(0700, "d")
    end
  end

end
