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

Tb::Cmd.subcommands << 'gsub'

class Tb::Cmd
  @opt_gsub_e = nil
  @opt_gsub_f = nil
end

class << Tb::Cmd
  attr_accessor :opt_gsub_e
  attr_accessor :opt_gsub_f
end

def (Tb::Cmd).op_gsub
  op = OptionParser.new
  op.banner = 'Usage: tb gsub [OPTS] REGEXP STRING [TABLE]'
  op.def_option('-h', 'show help message') { puts op; exit 0 }
  op.def_option('-N', 'use numeric field name') { Tb::Cmd.opt_N = true }
  op.def_option('-f FIELD', 'search field') {|field| Tb::Cmd.opt_gsub_f = field }
  op.def_option('-e REGEXP', 'predicate written in ruby.  A hash is given as _.  no usual regexp argument.') {|pattern| Tb::Cmd.opt_gsub_e = pattern }
  op.def_option('--no-pager', 'don\'t use pager') { Tb::Cmd.opt_no_pager = true }
  op
end

def (Tb::Cmd).main_gsub(argv)
  op_gsub.parse!(argv)
  if Tb::Cmd.opt_gsub_e
    re = Regexp.new(Tb::Cmd.opt_gsub_e)
  else
    re = Regexp.new(argv.shift)
  end
  repl = argv.shift
  filename = argv.empty? ? '-' : argv.shift
  warn "extra arguments: #{argv.join(" ")}" if !argv.empty?
  tablereader_open(filename) {|tblreader|
    with_table_stream_output {|gen|
      gen.output_header tblreader.header
      tblreader.each {|ary|
        if Tb::Cmd.opt_gsub_f
          ary2 = []
          ary.each_with_index {|str, i|
            f = tblreader.field_from_index_ex(i)
            if f == Tb::Cmd.opt_gsub_f
              str ||= ''
              ary2 << str.gsub(re, repl)
            else
              ary2 << str
            end
          }
        else
          ary2 = ary.map {|s|
            s ||= ''
            s.gsub(re, repl)
          }
        end
        gen << ary2
      }
    }
  }
end
