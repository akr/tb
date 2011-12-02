# Copyright (C) 2011 Tanaka Akira  <akr@fsij.org>
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

Tb::Cmd.subcommands << 'mheader'

$opt_mheader_count = nil
def op_mheader
  op = OptionParser.new
  op.banner = 'Usage: tb mheader [OPTS] [TABLE]'
  op.def_option('-h', 'show help message') { puts op; exit 0 }
  op.def_option('-c N', 'number of header records') {|arg| $opt_mheader_count = arg.to_i }
  op.def_option('--no-pager', 'don\'t use pager') { $opt_no_pager = true }
  op
end

def main_mheader(argv)
  op_mheader.parse!(argv)
  filename = argv.shift || '-'
  warn "extra arguments: #{argv.join(" ")}" if !argv.empty?
  header = []
  if $opt_mheader_count
    c = $opt_mheader_count
    header_end_p = lambda {
      c -= 1
      c == 0 ? header.map {|a| a.compact.join(' ').strip } : nil
    }
  else
    header_end_p = lambda {
      h2 = header.map {|a| a.compact.join(' ').strip }.uniq
      header.length == h2.length ? h2 : nil
    }
  end
  with_table_stream_output {|gen|
    Tb::Reader.open(filename, {:numeric=>true}) {|tblreader|
      tblreader.each {|ary|
        if header
          ary.each_with_index {|v,i|
            header[i] ||= []
            header[i] << v if header[i].empty? || header[i].last != v
          }
          h2 = header_end_p.call
          if h2
            gen << h2
            header = nil
          end
        else
          gen << ary
        end
      }
    }
  }
  if header
    warn "no header found."
  end
end

