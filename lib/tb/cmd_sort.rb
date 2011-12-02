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

$opt_sort_f = nil
def op_sort
  op = OptionParser.new
  op.banner = 'Usage: tb sort [OPTS] [TABLE]'
  op.def_option('-h', 'show help message') { puts op; exit 0 }
  op.def_option('-N', 'use numeric field name') { $opt_N = true }
  op.def_option('-f FIELD,...', 'specify sort keys') {|fs| $opt_sort_f = fs }
  op.def_option('--no-pager', 'don\'t use pager') { $opt_no_pager = true }
  op
end

def main_sort(argv)
  op_sort.parse!(argv)
  filename = argv.empty? ? '-' : argv.shift
  warn "extra arguments: #{argv.join(" ")}" if !argv.empty?
  if $opt_sort_f
    fs = split_field_list_argument($opt_sort_f)
  else
    fs = nil
  end
  tbl = load_table(filename)
  if fs
    blk = lambda {|rec| fs.map {|f| comparison_value(rec[f]) } }
  else
    blk = lambda {|rec| rec.map {|k, v| comparison_value(v) } }
  end
  tbl2 = tbl.reorder_records_by(&blk)
  with_output {|out|
    tbl_generate_csv(tbl2, out)
  }
end


