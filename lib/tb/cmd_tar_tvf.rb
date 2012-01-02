# Copyright (C) 2012 Tanaka Akira  <akr@fsij.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

Tb::Cmd.subcommands << 'tar-tvf'

Tb::Cmd.default_option[:opt_tar_tvf_l] = 0
Tb::Cmd.default_option[:opt_tar_tvf_ustar] = nil

def (Tb::Cmd).op_tar_tvf
  op = OptionParser.new
  op.banner = "Usage: tb tar-tvf [OPTS] [TAR-FILE ...]\n" +
    "Show the file listing of tar file."
  define_common_option(op, "hNo", "--no-pager")
  op.def_option('-l', 'show more attributes.') {|fs| Tb::Cmd.opt_tar_tvf_l += 1 }
  op.def_option('--ustar', 'ustar format (POSIX.1-1988).  No GNU and POSIX.1-2001 extension.') {|fs| Tb::Cmd.opt_tar_tvf_ustar = true }
  op
end

Tb::Cmd::TAR_RECORD_LENGTH = 512
Tb::Cmd::TAR_HEADER_STRUCTURE = [
  [:name, "Z100"],      # [POSIX] NUL-terminated character strings except when all characters in the array contain non-NUL characters including the last character.
  [:mode, "A8"],        # [POSIX] leading zero-filled octal numbers using digits which terminated by one or more <space> or NUL characters.
  [:uid, "A8"],         # [POSIX] leading zero-filled octal numbers using digits which terminated by one or more <space> or NUL characters.
  [:gid, "A8"],         # [POSIX] leading zero-filled octal numbers using digits which terminated by one or more <space> or NUL characters.
  [:size, "A12"],       # [POSIX] leading zero-filled octal numbers using digits which terminated by one or more <space> or NUL characters.
  [:mtime, "A12"],      # [POSIX] leading zero-filled octal numbers using digits which terminated by one or more <space> or NUL characters.
  [:chksum, "A8"],      # [POSIX] leading zero-filled octal numbers using digits which terminated by one or more <space> or NUL characters.
  [:typeflag, "a1"],    # [POSIX] a single character.
  [:linkname, "Z100"],  # [POSIX] NUL-terminated character strings except when all characters in the array contain non-NUL characters including the last character.
  [:magic, "Z6"],       # [POSIX] terminated by a NUL character.
  [:version, "Z2"],     # [POSIX] two octets containing the characters "00" (zero-zero)
  [:uname, "Z32"],      # [POSIX] terminated by a NUL character.
  [:gname, "Z32"],      # [POSIX] terminated by a NUL character.
  [:devmajor, "A8"],    # [POSIX] leading zero-filled octal numbers using digits which terminated by one or more <space> or NUL characters.
  [:devminor, "A8"],    # [POSIX] leading zero-filled octal numbers using digits which terminated by one or more <space> or NUL characters.
  [:prefix, "Z155"],    # [POSIX] NUL-terminated character strings except when all characters in the array contain non-NUL characters including the last character.
]
Tb::Cmd::TAR_HEADER_TEPMLATE = Tb::Cmd::TAR_HEADER_STRUCTURE.map {|n, t| t }.join('')

Tb::Cmd::TAR_TYPEFLAG = {
  "\0" => :regular,             # [POSIX] For backwards-compatibility.
  '0' => :regular,              # [POSIX]
  '1' => :link,                 # [POSIX]
  '2' => :symlink,              # [POSIX]
  '5' => :directory,            # [POSIX]
  '3' => :character_special,    # [POSIX]
  '4' => :block_special,        # [POSIX]
  '6' => :fifo,                 # [POSIX]
  '7' => :contiguous,           # [POSIX] Reserved for high-performance file.  (It is come from "contiguous file" (S_IFCTG) of Masscomp?)
}

Tb::Cmd::TAR_PAX_KEYWORD_RECOGNIZERS = {
  'atime' => [:atime, lambda {|val| Time.at(val.to_f) }], # xxx: to_f is not accurate
  'mtime' => [:mtime, lambda {|val| Time.at(val.to_f) }], # xxx: to_f is not accurate
  'ctime' => [:ctime, lambda {|val| Time.at(val.to_f) }], # xxx: to_f is not accurate
  'gid' => [:gid, lambda {|val| val.to_i }],
  'gname' => [:gname, lambda {|val| val }],
  'uid' => [:uid, lambda {|val| val.to_i }],
  'uname' => [:uname, lambda {|val| val }],
  'linkpath' => [:linkname, lambda {|val| val }],
  'path' => [:path, lambda {|val| val }],
  'size' => [:size, lambda {|val| val.to_i }],
}

Tb::Cmd::TAR_CSV_HEADER = %w[mode filemode uid user gid group devmajor devminor size mtime path linkname]
Tb::Cmd::TAR_CSV_LONG_HEADER = %w[mode filemode uid user gid group devmajor devminor size mtime atime ctime path linkname tar_typeflag tar_magic tar_version tar_chksum]

def (Tb::Cmd).tar_tvf_parse_header(header_record)
  ary = header_record.unpack(Tb::Cmd::TAR_HEADER_TEPMLATE)
  h = {}
  Tb::Cmd::TAR_HEADER_STRUCTURE.each_with_index {|(k, _), i|
    h[k] = ary[i]
  }
  [:mode, :uid, :gid, :size, :mtime, :chksum, :devmajor, :devminor].each {|k|
    h[k] = h[k].to_i(8)
  }
  h[:mtime] = Time.at(h[:mtime])
  if h[:prefix].empty?
    h[:path] = h[:name]
  else
    h[:path] = h[:prefix] + '/' + h[:name]
  end
  header_record_for_chksum = header_record.dup
  header_record_for_chksum[148, 8] = ' ' * 8
  if header_record_for_chksum.sum(0) != h[:chksum]
    warn "invalid checksum: #{h[:path].inspect}"
  end
  h
end

def (Tb::Cmd).tar_tvf_each(f)
  prefix_parameters = {}
  while true
    header_record = f.read(Tb::Cmd::TAR_RECORD_LENGTH)
    if !header_record
      break
    end
    if header_record.length != Tb::Cmd::TAR_RECORD_LENGTH
      warn "premature end of tar archive"
      break
    end
    if /\A\0*\z/ =~ header_record
      second_end_of_archive_indicator_record = f.read(Tb::Cmd::TAR_RECORD_LENGTH)
      if !second_end_of_archive_indicator_record
        warn "premature end of tar archive indicator (no second record)"
        break
      end
      if second_end_of_archive_indicator_record.length != Tb::Cmd::TAR_RECORD_LENGTH
        warn "premature end of second record of end of tar archive indicator"
        break
      end
      if /\A\0*\z/ !~ header_record
        warn "The second record of end of tar archive indicator is not zero"
        break
      end
      # There may be garbage after the end of tar archive indicator. 
      # It is acceptable.  ("ustar Interchange Format" in POSIX)
      break
    end
    h = tar_tvf_parse_header(header_record)
    content_numrecords = (h[:size] + Tb::Cmd::TAR_RECORD_LENGTH - 1) / Tb::Cmd::TAR_RECORD_LENGTH
    content_blocklength = content_numrecords * Tb::Cmd::TAR_RECORD_LENGTH
    if !Tb::Cmd.opt_tar_tvf_ustar
      extension_header = true
      case h[:typeflag]
      when 'L' # GNU
        content = f.read(content_blocklength)[0, h[:size]][/\A[^\0]*/]
        prefix_parameters[:path] = content
      when 'K' # GNU
        content = f.read(content_blocklength)[0, h[:size]][/\A[^\0]*/]
        prefix_parameters[:linkname] = content
      when 'x' # pax (POSIX.1-2001)
        content = f.read(content_blocklength)[0, h[:size]]
        while /\A(\d+) / =~ content
          lenlen = $&.length
          len = $1.to_i
          param = content[lenlen, len-lenlen]
          content = content[len..-1]
          if /\n\z/ =~ param
            param.chomp!("\n")
          else
            warn "pax hearder record doesn't end with a newline: #{param.inspect}"
          end
          if /=/ !~ param
            warn "pax hearder record doesn't contain a equal character: #{param.inspect}"
          else
            key = $`
            val = $'
            if Tb::Cmd::TAR_PAX_KEYWORD_RECOGNIZERS[key]
              if val == ''
                prefix_parameters[symkey] = nil
              else
                symkey, recognizer = Tb::Cmd::TAR_PAX_KEYWORD_RECOGNIZERS[key]
                prefix_parameters[symkey] = recognizer.call(val)
              end
            end
          end
        end
      else
        extension_header = false
      end
      next if extension_header
    end
    prefix_parameters.each {|k, v|
      if v.nil?
        h.delete k
      else
        h[k] = v
      end
    }
    yield h
    prefix_parameters = {}
    case Tb::Cmd::TAR_TYPEFLAG[h[:typeflag]]
    when :link, :symlink, :directory, :character_special, :block_special, :fifo
      # xxx: hardlink may have contents for posix archive.
      next
    end
    begin
      f.seek(content_blocklength, IO::SEEK_CUR)
    rescue Errno::ESPIPE
      content_numrecords.times {
        ret = f.read(Tb::Cmd::TAR_RECORD_LENGTH)
        if !ret || ret.length != Tb::Cmd::TAR_RECORD_LENGTH
          warn "premature end of tar archive content"
          break
        end
      }
    end
  end
end

def (Tb::Cmd).tar_tvf_open_with0(arg)
  if arg == '-'
    yield STDIN
  else
    open(arg, 'rb') {|f|
      yield f
    }
  end
end

def (Tb::Cmd).tar_tvf_open_with(arg)
  tar_tvf_open_with0(arg) {|f|
    magic = f.read(8)
    case magic
    when /\A\x1f\x8b/, /\A\037\235/ # \x1f\x8b is gzip format.  \037\235 is "compress" format of old Unix.
      decompression = ['gzip', '-dc']
    when /\ABZh/
      decompression = ['bzip2', '-dc']
    when /\A\xFD7zXZ\x00/
      decompression = ['xz', '-dc']
    end
    begin
      f.rewind
      seek_success = true
    rescue Errno::ESPIPE
      seek_success = false
    end
    # Ruby 1.9 dependent.
    if decompression
      if seek_success
        IO.popen(decompression + [{:in => f}], 'rb') {|pipe|
          yield pipe
        }
      else
        IO.pipe {|r, w|
          w.binmode
          IO.popen(decompression + [{:in => r}], 'rb') {|pipe|
            w << magic
            th = Thread.new {
              IO.copy_stream(f, w)
              w.close
            }
            begin
              yield pipe
            ensure
              th.join
            end
          }
        }
      end
    else
      if seek_success
        yield f
      else
        IO.pipe {|r, w|
          w.binmode
          w << magic
          th = Thread.new {
            IO.copy_stream(f, w)
            w.close
          }
          begin
            yield pipe
          ensure
            th.join
          end
        }
      end
    end
  }
end

def (Tb::Cmd).tar_tvf_format_filemode(typeflag, mode)
  entry_type =
    case Tb::Cmd::TAR_TYPEFLAG[typeflag]
    when :regular then '-'
    when :directory then 'd'
    when :character_special then 'c'
    when :block_special then 'b'
    when :fifo then 'p'
    when :symlink then 'l'
    when :link then 'h'
    when :contiguous then 'C'
    else '?'
    end
  m = mode
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

def (Tb::Cmd).main_tar_tvf(argv)
  op_tar_tvf.parse!(argv)
  exit_if_help('tar-tvf')
  argv = ['-'] if argv.empty?
  with_table_stream_output {|gen|
    if Tb::Cmd.opt_tar_tvf_l == 0
      header = Tb::Cmd::TAR_CSV_HEADER
    else
      header = Tb::Cmd::TAR_CSV_LONG_HEADER
    end
    gen.output_header header
    argv.each {|filename|
      tar_tvf_open_with(filename) {|f|
        tar_tvf_each(f) {|h|
          formatted = {}
          formatted["mode"] = sprintf("0%o", h[:mode])
          formatted["filemode"] = tar_tvf_format_filemode(h[:typeflag], h[:mode])
          formatted["uid"] = h[:uid].to_s
          formatted["gid"] = h[:gid].to_s
          formatted["size"] = h[:size].to_s
          formatted["mtime"] = h[:mtime].iso8601
          formatted["atime"] = h[:atime].iso8601 if h[:atime]
          formatted["ctime"] = h[:ctime].iso8601 if h[:ctime]
          formatted["user"] = h[:uname]
          formatted["group"] = h[:gname]
          formatted["devmajor"] = h[:devmajor].to_s
          formatted["devminor"] = h[:devminor].to_s
          formatted["path"] = h[:path]
          formatted["linkname"] = h[:linkname]
          formatted["tar_chksum"] = h[:chksum]
          formatted["tar_typeflag"] = h[:typeflag]
          formatted["tar_magic"] = h[:magic]
          formatted["tar_version"] = h[:version]
          gen << formatted.values_at(*header)
        }
      }
    }
  }
end
