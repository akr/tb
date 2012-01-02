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
  tbl = Tb::CatReader.open(argv, Tb::Cmd.opt_N) {|reader| build_table(reader) }
  if fs
    blk = lambda {|rec| fs.map {|f| smart_cmp_value(rec[f]) } }
  else
    blk = lambda {|rec| rec.map {|k, v| smart_cmp_value(v) } }
  end
  tbl2 = tbl.reorder_records_by(&blk)
  with_output {|out|
    tbl_generate_csv(tbl2, out)
  }
end


