# Copyright (C) 2012 Tanaka Akira  <akr@fsij.org>
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

Tb::Cmd.subcommands << 'unmelt'

Tb::Cmd.default_option[:opt_unmelt_recnum] = nil
Tb::Cmd.default_option[:opt_unmelt_keys] = []
Tb::Cmd.default_option[:opt_unmelt_variable_field] = 'variable'
Tb::Cmd.default_option[:opt_unmelt_value_field] = 'value'
Tb::Cmd.default_option[:opt_unmelt_missing_value] = nil

def (Tb::Cmd).op_unmelt
  op = OptionParser.new
  op.banner = "Usage: tb unmelt [OPTS] [TABLE ...]\n" +
    "merge melted records into a record."
  define_common_option(op, "hNo", "--no-pager")
  op.def_option('--recnum[=FIELD]',
                'use FIELD as an additional key and remove it from the result. (default: not specified)') {|field|
    Tb::Cmd.opt_unmelt_recnum = field || 'recnum'
  }
  op.def_option('--keys FIELD,...', 'key fields. (default: all fields except variable and value)') {|fields|
    Tb::Cmd.opt_unmelt_keys.concat split_field_list_argument(fields)
  }
  op.def_option('--variable-field FIELD', 'variable field. (default: variable)') {|field|
    Tb::Cmd.opt_unmelt_variable_field = field
  }
  op.def_option('--value-field FIELD', 'value field. (default: value)') {|field|
    Tb::Cmd.opt_unmelt_value_field = field
  }
  op.def_option('--missing-value FIELD', 'used for missing values. (default: not specified)') {|value|
    Tb::Cmd.opt_unmelt_missing_value = value
  }
  op
end

Tb::Cmd.def_vhelp('unmelt', <<'End')
Example:

  % cat tst.csv
  foo,variable,value
  A,bar,1
  A,baz,x
  B,bar,2
  B,baz,y
  % tb unmelt tst.csv
  foo,bar,baz
  A,1,x
  B,2,y
End

def (Tb::Cmd).main_unmelt(argv)
  op_unmelt.parse!(argv)
  exit_if_help('unmelt')
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  if Tb::Cmd.opt_unmelt_keys.empty?
    key_fields = nil
  else
    if Tb::Cmd.opt_unmelt_recnum
      key_fields = [Tb::Cmd.opt_unmelt_recnum]
    else
      key_fields = []
    end
    key_fields += Tb::Cmd.opt_unmelt_keys
  end
  melt_fields_hash = {}
  er = Tb::Enumerator.new {|y|
    creader.chunk {|pairs|
      keys = {}
      if key_fields
        key_fields.each {|k|
          keys[k] = pairs[k]
        }
      else
        pairs.each_key {|k|
          next if k == Tb::Cmd.opt_unmelt_variable_field ||
                  k == Tb::Cmd.opt_unmelt_value_field
          keys[k] = pairs[k]
        }
      end
      keys
    }.each {|keys, pairs_ary|
      if Tb::Cmd.opt_unmelt_recnum
        keys.delete Tb::Cmd.opt_unmelt_recnum
      end
      rec = keys.dup
      pairs_ary.each {|pairs|
        var = pairs[Tb::Cmd.opt_unmelt_variable_field]
        val = pairs[Tb::Cmd.opt_unmelt_value_field]
        melt_fields_hash[var] = true
        if rec.has_key? var
          y.yield rec
          rec = keys.dup
        end
        rec[var] = val
      }
      y.yield rec
    }
  }
  if !Tb::Cmd.opt_unmelt_missing_value
    er2 = er
  else
    er2 = Tb::Enumerator.new {|y|
      er.to_fileenumerator.with_header {|header|
        y.set_header header
      }.each {|pairs|
        melt_fields_hash.each_key {|f|
          pairs[f] ||= Tb::Cmd.opt_unmelt_missing_value
        }
        y.yield pairs
      }
    }
  end
  output_tbenum(er2)
end

