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

Tb::Cmd.subcommands << 'group'

Tb::Cmd.default_option[:opt_group_fields] = []

def (Tb::Cmd).op_group
  op = OptionParser.new
  op.banner = "Usage: tb group [OPTS] KEY-FIELD1,... [TABLE ...]\n" +
    "Group and aggregate rows."
  define_common_option(op, "hNo", "--no-pager")
  op.def_option('-a AGGREGATION-SPEC[,NEW-FIELD]',
                '--aggregate AGGREGATION-SPEC[,NEW-FIELD]') {|arg| Tb::Cmd.opt_group_fields << arg }
  op.def_option('--no-pager', 'don\'t use pager') { Tb::Cmd.opt_no_pager = true }
  op
end

def (Tb::Cmd).main_group(argv)
  op_group.parse!(argv)
  exit_if_help('group')
  err("no key fields given.") if argv.empty?
  kfs = split_field_list_argument(argv.shift)
  opt_group_fields = Tb::Cmd.opt_group_fields.map {|arg|
    aggregation_spec, new_field = split_field_list_argument(arg)
    new_field ||= aggregation_spec
    [new_field,
      lambda {|fields|
        begin
          make_aggregator(aggregation_spec, fields)
        rescue ArgumentError
          err($!.message)
        end
      }
    ]
  }
  argv = ['-'] if argv.empty?
  h = {}
  Tb::CatReader.open(argv, Tb::Cmd.opt_N) {|tblreader|
    result_fields = kfs + opt_group_fields.map {|nf, maker| nf }
    first = true
    header_fixed = nil
    tblreader.each {|pairs|
      if first
        first = false
        header_fixed = tblreader.header_fixed
      end
      kvs = kfs.map {|kf| pairs[kf] }
      ary = header_fixed.map {|f| pairs[f] }
      if !h.include?(kvs)
        h[kvs] = opt_group_fields.map {|nf, maker| ag = maker.call(header_fixed); ag.update(ary); ag }
      else
        h[kvs].each {|ag|
          ag.update(ary)
        }
      end
    }
    result = Tb.new(result_fields)
    h.keys.sort_by {|k| k.map {|v| smart_cmp_value(v) } }.each {|k|
      a = h[k]
      result.insert_values result_fields, k + a.map {|ag| ag.finish }
    }
    with_output {|out|
      tbl_generate_csv(result, out)
    }
  }
end

