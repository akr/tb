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

Tb::Cmd.default_option[:opt_join_outer] = nil
Tb::Cmd.default_option[:opt_join_outer_missing] = nil

def (Tb::Cmd).op_join
  op = OptionParser.new
  op.banner = 'Usage: tb join [OPTS] [TABLE ...]'
  op.def_option('-h', 'show help message') { puts op; exit 0 }
  op.def_option('-d', '--debug', 'show debug message') { Tb::Cmd.opt_debug += 1 }
  op.def_option('-N', 'use numeric field name') { Tb::Cmd.opt_N = true }
  op.def_option('--outer', 'outer join') { Tb::Cmd.opt_join_outer = :full }
  op.def_option('--left', 'left outer join') { Tb::Cmd.opt_join_outer = :left }
  op.def_option('--right', 'right outer join') { Tb::Cmd.opt_join_outer = :right }
  op.def_option('--outer-missing=DEFAULT', 'missing value for outer join') {|missing|
    Tb::Cmd.opt_join_outer ||= :full
    Tb::Cmd.opt_join_outer_missing = missing
  }
  op.def_option('-o filename', 'output to specified filename') {|filename| Tb::Cmd.opt_output = filename }
  op.def_option('--no-pager', 'don\'t use pager') { Tb::Cmd.opt_no_pager = true }
  op
end

def (Tb::Cmd).main_join(argv)
  op_join.parse!(argv)
  result = Tb.new([], [])
  retain_left = false
  retain_right = false
  case Tb::Cmd.opt_join_outer
  when :full
    retain_left = true
    retain_right = true
  when :left
    retain_left = true
  when :right
    retain_right = true
  when nil
  else
    raise "unexpected Tb::Cmd.opt_join_outer: #{Tb::Cmd.opt_join_outer.inspect}"
  end
  if Tb::Cmd.opt_join_outer
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

