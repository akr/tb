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
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  result = Tb::Enumerator.new {|y|
    er = creader.extsort_by {|pairs|
      kfs.map {|f| smart_cmp_value(pairs[f]) }
    }
    header = nil
    row = nil
    agg = nil
    er2 = er.with_header {|header0|
      header = header0
      y.set_header(kfs + opt_group_fields.map {|f, maker| f })
    }
    boudary_p = lambda {|pairs1, pairs2|
      kfs.any? {|f| pairs1[f] != pairs2[f] }
    }
    before = lambda {|first_pairs|
      row = {}
      kfs.each {|f|
        row[f] = first_pairs[f]
      }
      agg = {}
      opt_group_fields.each {|f, maker|
        agg[f] = maker.call(header)
      }
    }
    body = lambda {|pairs|
      ary = header.map {|f| pairs[f] }
      opt_group_fields.each {|f, maker|
        agg[f].update(ary)
      }
    }
    after = lambda {|last_pairs|
      opt_group_fields.each {|f, maker|
        row[f] = agg[f].finish
      }
      y.yield row
    }
    er2.each_group_element(boudary_p, before, body, after)
  }
  with_output {|out|
    result.write_to_csv_to_io(out, !Tb::Cmd.opt_N)
  }
end

