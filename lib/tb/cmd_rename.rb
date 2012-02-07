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

Tb::Cmd.subcommands << 'rename'

def (Tb::Cmd).op_rename
  op = OptionParser.new
  op.banner = "Usage: tb rename [OPTS] SRC,DST,... [TABLE]\n" +
    "Rename field names."
  define_common_option(op, "ho", "--no-pager")
  op
end

def (Tb::Cmd).main_rename(argv)
  op_rename.parse!(argv)
  exit_if_help('rename')
  err('rename fields not given.') if argv.empty?
  fs = split_field_list_argument(argv.shift)
  argv = ['-'] if argv.empty?
  h = {}
  fs.each_slice(2) {|sf, df| h[sf] = df }
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  er = Tb::Enumerator.new {|y|
    header = nil
    creader.with_header {|header0|
      header = header0
      h.each {|sf, df|
        unless header.include? sf
          err "field not found: #{sf.inspect}"
        end
      }
      y.set_header header.map {|f| h.fetch(f, f) }
    }.each {|pairs|
      y.yield Hash[pairs.map {|f, v| [h.fetch(f, f), v] }]
    }
  }
  with_output {|out|
    er.write_to_csv(out, !Tb::Cmd.opt_N)
  }
end

