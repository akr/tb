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

Tb::Cmd.subcommands << 'consecutive'

Tb::Cmd.default_option[:opt_consecutive_n] = 2

def (Tb::Cmd).op_consecutive
  op = OptionParser.new
  op.banner = 'Usage: tb consecutive [OPTS] [TABLE ...]'
  define_common_option(op, "ho", "--no-pager")
  op.def_option('-n NUM', 'gather NUM records.  (default: 2)') {|n| Tb::Cmd.opt_consecutive_n = n.to_i }
  op
end

Tb::Cmd.def_vhelp('consecutive', <<'End')
Example:

  % cat tst.csv 
  a,b,c
  0,1,2
  4,5,6
  7,8,9
  % tb consecutive tstcsv
  a_1,b_1,c_1,a_2,b_2,c_2
  0,1,2,4,5,6
  4,5,6,7,8,9

Note:
* Header fields must exist.  A fields which don't have header is ignored.
End

def (Tb::Cmd).main_consecutive(argv)
  op_consecutive.parse!(argv)
  exit_if_help('consecutive')
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  header = creader.header
  consecutive_header = []
  Tb::Cmd.opt_consecutive_n.times {|i|
    consecutive_header.concat header.map {|f| "#{f}_#{i+1}" }
  }
  with_table_stream_output {|gen|
    if !Tb::Cmd.opt_N
      gen << consecutive_header
    end
    buf = []
    creader.each {|ary|
      if header.length < ary.length
        ary = ary[0, header.length]
      elsif ary.length < header.length
        ary.concat([nil]*(header.length-ary.length))
      end
      buf << ary
      if buf.length == Tb::Cmd.opt_consecutive_n
        gen << buf.flatten
        buf.shift
      end
    }
  }
end
