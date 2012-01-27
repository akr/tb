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

Tb::Cmd.subcommands << 'mheader'

Tb::Cmd.default_option[:opt_mheader_count] = nil

def (Tb::Cmd).op_mheader
  op = OptionParser.new
  op.banner = "Usage: tb mheader [OPTS] [TABLE]\n" +
    "Collapse multi rows header."
  define_common_option(op, "ho", "--no-pager")
  op.def_option('-c N', 'number of header records') {|arg| Tb::Cmd.opt_mheader_count = arg.to_i }
  op
end

def (Tb::Cmd).main_mheader(argv)
  op_mheader.parse!(argv)
  exit_if_help('mheader')
  argv = ['-'] if argv.empty?
  header = []
  if Tb::Cmd.opt_mheader_count
    c = Tb::Cmd.opt_mheader_count
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
  creader = Tb::CatReader.open(argv, true)
  er = Tb::Enumerator.new {|y|
    creader.each {|pairs|
      if header
        ary = []
        pairs.each {|f, v| ary[f.to_i-1] = v }
        ary.each_with_index {|v,i|
          header[i] ||= []
          header[i] << v if header[i].empty? || header[i].last != v
        }
        h2 = header_end_p.call
        if h2
          pairs2 = Tb::Pairs.new(h2.map.with_index {|v, i| ["#{i+1}", v] })
          y.yield pairs2
          header = nil
        end
      else
        y.yield pairs
      end
    }
  }
  with_output {|out|
    er.write_to_csv(out, false)
  }
  if header
    warn "unique header fields not recognized."
  end
end

