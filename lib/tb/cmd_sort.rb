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

Tb::Cmd.subcommands << 'sort'

Tb::Cmd.default_option[:opt_sort_f] = nil

def (Tb::Cmd).op_sort
  op = OptionParser.new
  op.banner = "Usage: tb sort [OPTS] [TABLE]\n" +
    "Sort rows."
  define_common_option(op, "hNo", "--no-pager")
  op.def_option('-f FIELD,...', 'specify sort keys') {|fs| Tb::Cmd.opt_sort_f = fs }
  op
end

def (Tb::Cmd).main_sort(argv)
  op_sort.parse!(argv)
  exit_if_help('sort')
  argv = ['-'] if argv.empty?
  if Tb::Cmd.opt_sort_f
    fs = split_field_list_argument(Tb::Cmd.opt_sort_f)
  else
    fs = nil
  end
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  header = []
  if fs
    blk = lambda {|pairs| fs.map {|f| smart_cmp_value(pairs[f]) } }
  else
    blk = lambda {|pairs| header.map {|f| smart_cmp_value(pairs[f]) } }
  end
  er = Tb::Enumerator.new {|y|
    creader.with_cumulative_header {|header0|
      if header0
        y.set_header(header0)
      end
    }.each {|pairs, header1|
      header = header1
      y.yield pairs
    }
  }.extsort_by(&blk)
  with_output {|out|
    er.write_to_csv_to_io(out, !Tb::Cmd.opt_N)
  }
end


