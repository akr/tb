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

Tb::Cmd.subcommands << 'join'

Tb::Cmd.default_option[:opt_join_outer_missing] = nil
Tb::Cmd.default_option[:opt_join_retain_left] = nil
Tb::Cmd.default_option[:opt_join_retain_right] = nil

def (Tb::Cmd).op_join
  op = OptionParser.new
  op.banner = 'Usage: tb join [OPTS] [TABLE ...]'
  define_common_option(op, 'hNod', '--no-pager', '--debug')
  op.def_option('--outer', 'outer join') {
    Tb::Cmd.opt_join_retain_left = true
    Tb::Cmd.opt_join_retain_right = true
  }
  op.def_option('--left', 'left outer join') {
    Tb::Cmd.opt_join_retain_left = true
    Tb::Cmd.opt_join_retain_right = false
  }
  op.def_option('--right', 'right outer join') {
    Tb::Cmd.opt_join_retain_left = false
    Tb::Cmd.opt_join_retain_right = true
  }
  op.def_option('--outer-missing=DEFAULT', 'missing value for outer join') {|missing|
    if Tb::Cmd.opt_join_retain_left == nil
      Tb::Cmd.opt_join_retain_left = true
      Tb::Cmd.opt_join_retain_right = true
    end
    Tb::Cmd.opt_join_outer_missing = missing
  }
  op
end

def (Tb::Cmd).main_join(argv)
  op_join.parse!(argv)
  return show_help('join') if 0 < Tb::Cmd.opt_help
  result = Tb.new([], [])
  retain_left = Tb::Cmd.opt_join_retain_left
  retain_right = Tb::Cmd.opt_join_retain_right
  if retain_left || retain_right
    each_table_file(argv) {|tbl|
      STDERR.puts "shared keys: #{(result.list_fields & tbl.list_fields).inspect}" if 1 <= Tb::Cmd.opt_debug
      result = result.natjoin2_outer(tbl, Tb::Cmd.opt_join_outer_missing, retain_left, retain_right)
    }
  else
    each_table_file(argv) {|tbl|
      STDERR.puts "shared keys: #{(result.list_fields & tbl.list_fields).inspect}" if 1 <= Tb::Cmd.opt_debug
      result = result.natjoin2(tbl)
    }
  end
  with_output {|out|
    tbl_generate_csv(result, out)
  }
  true
end

