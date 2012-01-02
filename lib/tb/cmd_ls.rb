# Copyright (C) 2011 Tanaka Akira  <akr@fsij.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the following
#     disclaimer in the documentation and/or other materials provided
#     with the distribution.
#  3. The name of the author may not be used to endorse or promote
#     products derived from this software without specific prior
#     written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Tb::Cmd.subcommands << 'ls'

Tb::Cmd.default_option[:opt_ls_a] = nil
Tb::Cmd.default_option[:opt_ls_A] = nil
Tb::Cmd.default_option[:opt_ls_l] = 0
Tb::Cmd.default_option[:opt_ls_R] = nil

def (Tb::Cmd).op_ls
  op = OptionParser.new
  op.banner = "Usage: tb ls [OPTS] [FILE ...]\n" +
    "List directory entries as a table."
  define_common_option(op, "hNo", "--no-pager")
  op.def_option('-a', 'don\'t ignore filenames beginning with a period.') {|fs| Tb::Cmd.opt_ls_a = true }
  op.def_option('-A', 'don\'t ignore filenames beginning with a period, except "." and "..".') {|fs| Tb::Cmd.opt_ls_A = true }
  op.def_option('-l', 'show attributes.  -ll for more attributes.') {|fs| Tb::Cmd.opt_ls_l += 1 }
  op.def_option('-R', 'recursive.') {|fs| Tb::Cmd.opt_ls_R = true }
  op
end

def (Tb::Cmd).main_ls(argv)
  op_ls.parse!(argv)
  exit_if_help('ls')
  argv = ['.'] if argv.empty?
  @fail = false
  with_table_stream_output {|gen|
    if Tb::Cmd.opt_ls_l == 0
      gen.output_header ['filename'] # don't generate the header when -N.
    else
      gen.output_header(ls_long_header()) # don't generate the header when -N.
    end
    argv.each {|arg|
      ls_run(gen, Pathname(real_pathname_string(arg)))
    }
  }
  if @fail
    exit false
  end
end

def (Tb::Cmd).ls_run(gen, path)
  st = ls_get_stat(path)
  return if !st
  if st.directory?
    ls_dir(gen, path, st)
  else
    ls_file(gen, path, st)
  end
end

def (Tb::Cmd).ls_dir(gen, dir, st)
  begin
    entries = Dir.entries(dir)
  rescue SystemCallError
    @fail = true
    warn "tb: #{$!}: #{dir}"
    return
  end
  entries.map! {|filename| real_pathname_string(filename) }
  entries = entries.sort_by {|filename| smart_cmp_value(filename) }
  if Tb::Cmd.opt_ls_a || Tb::Cmd.opt_ls_A
    entries1, entries2 = entries.partition {|filename| /\A\./ =~ filename }
    entries0, entries1 = entries1.partition {|filename| filename == '.' || filename == '..' }
    entries0.sort!
    if Tb::Cmd.opt_ls_A
      entries = entries1 + entries2
    else
      entries = entries0 + entries1 + entries2
    end
  else
    entries.reject! {|filename| /\A\./ =~ filename }
  end
  if !Tb::Cmd.opt_ls_R
    entries.each {|filename|
      ls_file(gen, dir + filename, nil)
    }
  else
    dirs = []
    entries.each {|filename|
      path = dir + filename
      st2 = ls_get_stat(path)
      next if !st2
      if filename == '.' || filename == '..'
        if dir.to_s != '.'
          path = Pathname(dir.to_s + "/" + filename)
        end
        ls_file(gen, path, st2)
      elsif st2.directory?
        dirs << [path, st2]
      else
        ls_file(gen, path, st2)
      end
    }
    dirs.each {|path, st2|
      ls_file(gen, path, st2)
      ls_dir(gen, path, st2)
    }
  end
end

def (Tb::Cmd).ls_file(gen, path, st)
  if 0 < Tb::Cmd.opt_ls_l
    if !st
      st = ls_get_stat(path)
      return if !st
    end
    gen << ls_long_info(path, st)
  else
    gen << [path.to_s]
  end
end

def (Tb::Cmd).ls_get_stat(path)
  begin
    st = path.lstat
  rescue SystemCallError
    @fail = true
    warn "tb: #{$!}: #{path}"
    return nil
  end
  st
end

def (Tb::Cmd).ls_long_header
  if 1 < Tb::Cmd.opt_ls_l
    %w[dev ino mode filemode nlink uid user gid group rdev size blksize blocks atime mtime ctime filename symlink]
  else
    %w[filemode nlink user group size mtime filename symlink]
  end
end

def (Tb::Cmd).ls_long_info(path, st)
  ls_long_header.map {|info_type|
    self.send("ls_info_#{info_type}", path, st)
  }
end

def (Tb::Cmd).ls_info_dev(path, st) sprintf("0x%x", st.dev) end
def (Tb::Cmd).ls_info_ino(path, st) st.ino end
def (Tb::Cmd).ls_info_mode(path, st) sprintf("0%o", st.mode) end
def (Tb::Cmd).ls_info_nlink(path, st) st.nlink end
def (Tb::Cmd).ls_info_uid(path, st) st.uid end
def (Tb::Cmd).ls_info_gid(path, st) st.gid end
def (Tb::Cmd).ls_info_rdev(path, st) sprintf("0x%x", st.rdev) end
def (Tb::Cmd).ls_info_size(path, st) st.size end
def (Tb::Cmd).ls_info_blksize(path, st) st.blksize end
def (Tb::Cmd).ls_info_blocks(path, st) st.blocks end

def (Tb::Cmd).ls_info_filemode(path, st)
  entry_type =
    case st.ftype
    when "file" then '-'
    when "directory" then 'd'
    when "characterSpecial" then 'c'
    when "blockSpecial" then 'b'
    when "fifo" then 'p'
    when "link" then 'l'
    when "socket" then 's'
    when "unknown" then '?'
    else '?'
    end
  m = st.mode
  sprintf("%s%c%c%c%c%c%c%c%c%c",
    entry_type,
    (m & 0400 == 0 ? ?- : ?r),
    (m & 0200 == 0 ? ?- : ?w),
    (m & 0100 == 0 ? (m & 04000 == 0 ? ?- : ?S) :
                     (m & 04000 == 0 ? ?x : ?s)),
    (m & 0040 == 0 ? ?- : ?r),
    (m & 0020 == 0 ? ?- : ?w),
    (m & 0010 == 0 ? (m & 02000 == 0 ? ?- : ?S) :
                     (m & 02000 == 0 ? ?x : ?s)),
    (m & 0004 == 0 ? ?- : ?r),
    (m & 0002 == 0 ? ?- : ?w),
    (m & 0001 == 0 ? (m & 01000 == 0 ? ?- : ?T) :
                     (m & 01000 == 0 ? ?x : ?t)))
end

def (Tb::Cmd).ls_info_user(path, st)
  uid = st.uid
  begin
    pw = Etc.getpwuid(uid)
  rescue ArgumentError
  end
  if pw
    pw.name
  else
    uid
  end
end

def (Tb::Cmd).ls_info_group(path, st)
  gid = st.gid
  begin
    gr = Etc.getgrgid(gid)
  rescue ArgumentError
  end
  if gr
    gr.name
  else
    gid
  end
end

def (Tb::Cmd).ls_info_atime(path, st)
  if 1 < Tb::Cmd.opt_ls_l
    st.atime.iso8601(9)
  else
    st.atime.iso8601
  end
end

def (Tb::Cmd).ls_info_mtime(path, st)
  if 1 < Tb::Cmd.opt_ls_l
    st.mtime.iso8601(9)
  else
    st.mtime.iso8601
  end
end

def (Tb::Cmd).ls_info_ctime(path, st)
  if 1 < Tb::Cmd.opt_ls_l
    st.ctime.iso8601(9)
  else
    st.ctime.iso8601
  end
end

def (Tb::Cmd).ls_info_filename(path, st)
  path
end

def (Tb::Cmd).ls_info_symlink(path, st)
  return nil if !st.symlink?
  begin
    File.readlink(path)
  rescue SystemCallError
    @fail = true
    warn "tb: #{$!}: #{path}"
    return nil
  end
end

def (Tb::Cmd).real_pathname_string(str)
  if str.respond_to? :force_encoding
    # pathname is a sequence of bytes on Unix.
    str.dup.force_encoding("ASCII-8BIT")
  else
    str
  end
end
