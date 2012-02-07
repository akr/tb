# Copyright (C) 2011-2012 Tanaka Akira  <akr@fsij.org>
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

Tb::Cmd.subcommands << 'consecutive'

Tb::Cmd.default_option[:opt_consecutive_n] = 2

def (Tb::Cmd).op_consecutive
  op = OptionParser.new
  op.banner = "Usage: tb consecutive [OPTS] [TABLE ...]\n" +
    "Concatenate consecutive rows."
  define_common_option(op, "hNo", "--no-pager")
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
  a_1,a_2,b_1,b_2,c_1,c_2
  0,4,1,5,2,6
  4,7,5,8,6,9
End

def (Tb::Cmd).main_consecutive(argv)
  op_consecutive.parse!(argv)
  exit_if_help('consecutive')
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  er = Tb::Enumerator.new {|y|
    buf = []
    empty = true
    creader.with_cumulative_header {|header0|
      if header0
        y.set_header header0.map {|f| (1..Tb::Cmd.opt_consecutive_n).map {|i| "#{f}_#{i}" } }.flatten(1)
      end
    }.each {|pairs, header|
      buf << pairs
      if buf.length == Tb::Cmd.opt_consecutive_n
        pairs2 = {}
        header.each {|f|
          Tb::Cmd.opt_consecutive_n.times {|i|
            ps = buf[i]
            next if !ps.has_key?(f)
            v = ps[f]
            pairs2["#{f}_#{i+1}"] = v
          }
        }
        empty = false
        y.yield pairs2
        buf.shift
      end
    }
  }
  with_output {|out|
    er.write_to_csv(out, !Tb::Cmd.opt_N)
  }
end
