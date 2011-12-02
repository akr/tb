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

Tb::Cmd.subcommands << 'rename'

def op_rename
  op = OptionParser.new
  op.banner = 'Usage: tb rename [OPTS] SRC,DST,... [TABLE]'
  op.def_option('-h', 'show help message') { puts op; exit 0 }
  op.def_option('--no-pager', 'don\'t use pager') { $opt_no_pager = true }
  op
end

def main_rename(argv)
  op_rename.parse!(argv)
  fs = split_field_list_argument(argv.shift)
  filename = argv.shift || '-'
  warn "extra arguments: #{argv.join(" ")}" if !argv.empty?
  h = {}
  fs.each_slice(2) {|sf, df| h[sf] = df }
  tablereader_open(filename) {|tblreader|
    header = tblreader.header
    h.each {|sf, df|
      unless header.include? sf
        raise "field not defined: #{sf.inspect}"
      end
    }
    renamed_header = tblreader.header.map {|f| h.fetch(f, f) }
    with_table_stream_output {|gen|
      gen.output_header(renamed_header)
      tblreader.each {|ary|
        gen << ary
      }
    }
  }
end

