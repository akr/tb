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

  def with_stderr_log
    File.open("log", "w") {|log|
      with_stderr(log) {
        yield
      }
    }
    File.read('log')
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
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_equal(%w[filemode nlink user group size mtime filename symlink], header)
    assert_equal(8, row.length)
    assert_equal("-rwxr-xr--", row[header.index "filemode"])
    assert_equal("1", row[header.index "nlink"])
    assert_match(/\A\d+\z/, row[header.index "size"])
    assert_match(/\A\d+-\d\d-\d\dT\d\d:\d\d:\d\d/, row[header.index "mtime"])
    assert_equal("a", row[header.index "filename"])
    assert_equal(nil, row[header.index "symlink"])
  end

  def test_opt_l
    Dir.mkdir("d")
    File.open("d/a", "w") {}
    Dir.mkdir("d/d2")
    Tb::Cmd.main_ls(['-o', o="o.csv", '-l', 'd'])
    aa = CSV.read(o)
    assert_equal(3, aa.length)
    header, row1, row2 = aa
    i = header.index("filename")
    assert_equal("d/a", row1[i])
    assert_equal("d/d2", row2[i])
  end

  def test_opt_ll_single
    File.open("a", "w") {}
    File.chmod(0754, "a")
    Tb::Cmd.main_ls(['-o', o="o.csv", '-ll', 'a'])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_equal(%w[dev ino mode filemode nlink uid user gid group rdev size blksize blocks atime mtime ctime filename symlink], header)
    assert_match(/\A0x[0-9a-f]+\z/, row[header.index "dev"])
    assert_match(/\A\d+\z/, row[header.index "ino"])
    assert_match(/\A0[0-7]+\z/, row[header.index "mode"])
    assert_equal("-rwxr-xr--", row[header.index "filemode"])
    assert_equal("1", row[header.index "nlink"])
    assert_match(/\A\d+\z/, row[header.index "uid"])
    assert_match(/\A\d+\z/, row[header.index "gid"])
    assert_match(/\A0x[0-9a-f]+\z/, row[header.index "rdev"])
    assert_match(/\A\d+\z/, row[header.index "size"])
    assert_match(/\A\d+\z/, row[header.index "blksize"])
    assert_match(/\A\d+\z/, row[header.index "blocks"])
    assert_match(/\A\d+-\d\d-\d\dT\d\d:\d\d:\d\d/, row[header.index "atime"])
    assert_match(/\A\d+-\d\d-\d\dT\d\d:\d\d:\d\d/, row[header.index "mtime"])
    assert_match(/\A\d+-\d\d-\d\dT\d\d:\d\d:\d\d/, row[header.index "ctime"])
    assert_equal("a", row[header.index "filename"])
    assert_equal(nil, row[header.index "symlink"])
  end

  def test_opt_a
    Dir.mkdir("d")
    File.open("d/.foo", "w") {}
    Tb::Cmd.main_ls(['-o', o="o.csv", '-a', 'd'])
    aa = CSV.read(o)
    assert_equal(4, aa.length)
    header, row1, row2, row3 = aa
    assert_equal("d", row1[header.index "filename"]) # d/.
    assert_equal(".", row2[header.index "filename"]) # d/..
    assert_equal("d/.foo", row3[header.index "filename"])
  end

  def test_opt_A
    Dir.mkdir("d")
    File.open("d/.foo", "w") {}
    Tb::Cmd.main_ls(['-o', o="o.csv", '-A', 'd'])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_equal("d/.foo", row[header.index "filename"])
  end

  def test_opt_R
    Dir.mkdir("d")
    File.open("d/a", "w") {}
    Dir.mkdir("d/d2")
    File.open("d/d2/b", "w") {}
    File.open("d/d2/c", "w") {}
    Tb::Cmd.main_ls(['-o', o="o.csv", '-R', 'd'])
    aa = CSV.read(o)
    assert_equal(5, aa.length)
    header, row1, row2, row3, row4 = aa
    assert_equal("d/a", row1[header.index "filename"])
    assert_equal("d/d2", row2[header.index "filename"])
    assert_equal("d/d2/b", row3[header.index "filename"])
    assert_equal("d/d2/c", row4[header.index "filename"])
  end

  def test_opt_Ra
    Dir.mkdir("d")
    File.open("d/a", "w") {}
    Dir.mkdir("d/d2")
    File.open("d/d2/b", "w") {}
    File.open("d/d2/c", "w") {}
    Tb::Cmd.main_ls(['-o', o="o.csv", '-Ra', 'd'])
    aa = CSV.read(o)
    assert_equal(9, aa.length)
    header, *rows = aa
    assert_equal("d/.", rows[0][header.index "filename"])
    assert_equal("d/..", rows[1][header.index "filename"])
    assert_equal("d/a", rows[2][header.index "filename"])
    assert_equal("d/d2", rows[3][header.index "filename"])
    assert_equal("d/d2/.", rows[4][header.index "filename"])
    assert_equal("d/d2/..", rows[5][header.index "filename"])
    assert_equal("d/d2/b", rows[6][header.index "filename"])
    assert_equal("d/d2/c", rows[7][header.index "filename"])
  end

  def test_symlink
    File.symlink("a", "b")
    Tb::Cmd.main_ls(['-o', o="o.csv", '-l', 'b'])
    aa = CSV.read(o)
    assert_equal(2, aa.length)
    header, row = aa
    assert_equal("b", row[header.index "filename"])
    assert_equal("a", row[header.index "symlink"])
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

  def test_ls_info_symlink
    lsobj = Tb::Cmd::Ls.new(nil, {})
    st = Object.new
    def st.symlink?() true end
    log = with_stderr_log {
      assert_nil(lsobj.ls_info_symlink('.', st))
    }
    assert(!log.empty?)
  end

end

class TestTbCmdLsNoTmpDir < Test::Unit::TestCase
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

  def test_ls_info_filemode
    lsobj = Tb::Cmd::Ls.new(nil, {})
    st = Object.new
    def st.mode() 0 end
    def st.ftype() @ftype end
    def st.ftype=(arg) @ftype = arg end
    st.ftype = 'file'
    assert_equal("----------", lsobj.ls_info_filemode(nil, st))
    st.ftype = 'directory'
    assert_equal("d---------", lsobj.ls_info_filemode(nil, st))
    st.ftype = 'characterSpecial'
    assert_equal("c---------", lsobj.ls_info_filemode(nil, st))
    st.ftype = 'blockSpecial'
    assert_equal("b---------", lsobj.ls_info_filemode(nil, st))
    st.ftype = 'fifo'
    assert_equal("p---------", lsobj.ls_info_filemode(nil, st))
    st.ftype = 'link'
    assert_equal("l---------", lsobj.ls_info_filemode(nil, st))
    st.ftype = 'socket'
    assert_equal("s---------", lsobj.ls_info_filemode(nil, st))
    st.ftype = 'unknown'
    assert_equal("?---------", lsobj.ls_info_filemode(nil, st))
    st.ftype = 'foobar'
    assert_equal("?---------", lsobj.ls_info_filemode(nil, st))
  end

  def test_ls_info_user
    lsobj = Tb::Cmd::Ls.new(nil, {})
    st = Object.new
    # assumes Etc.getpwuid(-100) causes ArgumentError.
    def st.uid() -100 end
    assert_equal("-100", lsobj.ls_info_user(nil, st))
  end

  def test_ls_info_group
    lsobj = Tb::Cmd::Ls.new(nil, {})
    st = Object.new
    # assumes Etc.getgrgid(-200) causes ArgumentError.
    def st.gid() -200 end
    assert_equal("-200", lsobj.ls_info_group(nil, st))
  end

  def test_ls_info_atime
    lsobj = Tb::Cmd::Ls.new(nil, {:l => 1})
    st = Object.new
    def st.atime() Time.utc(2000) end
    assert_equal("2000-01-01T00:00:00Z", lsobj.ls_info_atime(nil, st))
  end

  def test_ls_info_ctime
    lsobj = Tb::Cmd::Ls.new(nil, {:l => 1})
    st = Object.new
    def st.ctime() Time.utc(2000) end
    assert_equal("2000-01-01T00:00:00Z", lsobj.ls_info_ctime(nil, st))
  end

end
