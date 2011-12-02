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

Tb::Cmd.subcommands << 'help'

def usage(status)
  print <<'End'
Usage:
  tb csv [OPTS] [TABLE]
  tb tsv [OPTS] [TABLE]
  tb json [OPTS] [TABLE]
  tb yaml [OPTS] [TABLE]
  tb pp [OPTS] [TABLE]
  tb grep [OPTS] REGEXP [TABLE]
  tb gsub [OPTS] REGEXP STRING [TABLE]
  tb sort [OPTS] [TABLE]
  tb select [OPTS] FIELD,... [TABLE]
  tb rename [OPTS] SRC,DST,... [TABLE]
  tb newfield [OPTS] FIELD RUBY-EXP [TABLE]
  tb cat [OPTS] [TABLE ...]
  tb join [OPTS] [TABLE ...]
  tb group [OPTS] [TABLE]
  tb cross [OPTS] [TABLE]
  tb shape [OPTS] [TABLE ...]
  tb mheader [OPTS] [TABLE]
  tb crop [OPTS] [TABLE]
End
  exit status
end

def main_help(argv)
  subcommand = argv.shift
  case subcommand
  when 'csv' then puts op_csv
  when 'tsv' then puts op_tsv
  when 'json' then puts op_json
  when 'yaml' then puts op_yaml
  when 'pp' then puts op_pp
  when 'grep' then puts op_grep
  when 'gsub' then puts op_gsub
  when 'sort' then puts op_sort
  when 'select' then puts op_select
  when 'rename' then puts op_rename
  when 'newfield' then puts op_newfield
  when 'cat' then puts op_cat
  when 'join' then puts op_join
  when 'group' then puts op_group
  when 'cross' then puts op_cross
  when 'shape' then puts op_shape
  when 'mheader' then puts op_mheader
  when 'crop' then puts op_crop
  when nil
    usage(true)
  else
    err "unexpected subcommand: #{subcommand.inspect}"
  end
end

