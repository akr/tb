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
  with_table_stream_output {|gen|
    first = true
    buf = []
    consecutive_header = nil
    creader.each {|pairs|
      if first
        first = false
        if header_fixed = creader.header_fixed
          consecutive_header = []
          header_fixed.each {|f|
            Tb::Cmd.opt_consecutive_n.times {|i|
              consecutive_header << "#{f}_#{i+1}"
            }
          }
          gen.output_header consecutive_header
        end
      end
      cfs = []
      pairs.map {|f, v|
        Tb::Cmd.opt_consecutive_n.times {|i|
          cfs << "#{f}_#{i+1}"
        }
      }
      consecutive_header |= cfs
      buf << pairs
      if buf.length == Tb::Cmd.opt_consecutive_n
        h = {}
        buf.each_with_index {|ps, i|
          ps.each_with_index {|(k, v), j|
            h["#{k}_#{i + 1}"] = v
          }
        }
        fs = consecutive_header.dup
        fs.pop while !fs.empty? && !h.include?(fs.last)
        gen << fs.map {|k| h[k] }
        buf.shift
      end
    }
  }
end
