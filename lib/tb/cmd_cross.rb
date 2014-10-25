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

Tb::Cmd.subcommands << 'cross'

Tb::Cmd.default_option[:opt_cross_fields] = []
Tb::Cmd.default_option[:opt_cross_compact] = false

def (Tb::Cmd).op_cross
  op = OptionParser.new
  op.banner = "Usage: tb cross [OPTS] VKEY-FIELD1,... HKEY-FIELD1,... [TABLE ...]\n" +
    "Create a cross table. (a.k.a contingency table, pivot table)"
  define_common_option(op, "ho", "--no-pager")
  op.def_option('-a AGGREGATION-SPEC[,NEW-FIELD]',
                '--aggregate AGGREGATION-SPEC[,NEW-FIELD]') {|arg| Tb::Cmd.opt_cross_fields << arg }
  op.def_option('-c', '--compact', 'compact format') { Tb::Cmd.opt_cross_compact = true }
  op
end

Tb::Cmd.def_vhelp('cross', <<'End')
Example:

  % cat tst.csv
  a,b,c
  A,X,2
  A,Y,3
  B,Y,4
  % tb cross a b tst.csv
  b,X,Y
  a,count,count
  A,1,1
  B,,1
  % tb cross -c a b tst.csv
  a,X,Y
  A,1,1
  B,,1
  % tb cross a b -a 'avg(c)' tst.csv
  b,X,Y
  a,avg(c),avg(c)
  A,2.0,3.0
  B,,4.0
End

def (Tb::Cmd).main_cross(argv)
  op_cross.parse!(argv)
  exit_if_help('cross')
  err('no vkey-fields given.') if argv.empty?
  vkfs = split_field_list_argument(argv.shift)
  err('no hkey-fields given.') if argv.empty?
  hkfs = split_field_list_argument(argv.shift)
  vhkfs = vkfs + hkfs
  if Tb::Cmd.opt_cross_fields.empty?
    num_aggregate_fields = 1
    opt_cross_fields = (vkfs + hkfs).map {|f| [f, Tb::Func::First, f] } +
      [['count', Tb::Func::Count, nil]]
  else
    num_aggregate_fields = Tb::Cmd.opt_cross_fields.length
    opt_cross_fields = (vkfs + hkfs).map {|f| [f, Tb::Func::First, f] } +
      Tb::Cmd.opt_cross_fields.map {|arg|
      agg_spec, new_field = split_field_list_argument(arg)
      new_field ||= agg_spec
      begin
        func_srcf = parse_aggregator_spec2(agg_spec)
      rescue ArgumentError
        err($!.message)
      end
      [new_field, *func_srcf]
    }
  end
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  er = Tb::Enumerator.new {|y|
    hvs_hash = {}
    hvs_list = nil
    aggs_hash = nil
    op = Tb::Zipper.new(opt_cross_fields.map {|dstf, func, srcf| func })
    er = creader.with_header {|header0|
      vhkfs.each {|f|
        if !header0.include?(f)
          err("field not found: #{f}")
        end
      }
    }.extsort_reduce(op) {|pairs|
      vvs = vkfs.map {|f| pairs[f] }
      hvs = hkfs.map {|f| pairs[f] }
      vvsc = vvs.map {|v| Tb::Func.smart_cmp_value(v) }
      hvsc = hvs.map {|v| Tb::Func.smart_cmp_value(v) }
      hvs_hash[hvs] = hvsc
      aggs = opt_cross_fields.map {|dstf, func, srcf| func.start(srcf ? pairs[srcf] : true) }
      [[vvsc, hvsc], aggs]
    }
    all_representative = lambda {|_| 1 }
    all_before = lambda {|_|
      hvs_list = hvs_hash.keys.sort_by {|hvs| hvs_hash[hvs] }
      n = vkfs.length + hvs_list.length * num_aggregate_fields
      header1 = (1..n).map {|i| i.to_s }
      y.set_header header1
      hkfs.each_with_index {|hkf, i|
        next if Tb::Cmd.opt_cross_compact && i == hkfs.length - 1
        h1 = {}
        j = vkfs.length
        h1[j.to_s] = hkf
        hvs_list.each {|hkvs|
          num_aggregate_fields.times {
            j += 1
            h1[j.to_s] = hkvs[i]
          }
        }
        y.yield h1
      }
      h2 = {}
      j = 0
      vkfs.each {|vkf|
        j += 1
        h2[j.to_s] = vkf
      }
      hvs_list.each {|hkvs|
        opt_cross_fields.last(num_aggregate_fields).each {|dstf, func, srcf|
          j += 1
          if Tb::Cmd.opt_cross_compact
            h2[j.to_s] = hkvs[-1]
          else
            h2[j.to_s] = dstf
          end
        }
      }
      y.yield h2
    }
    v_representative = lambda {|((vvsc, _), _)|
      vvsc
    }
    v_before = lambda {|_|
      aggs_hash = {}
    }
    body = lambda {|(_, aggs)|
      hvs = aggs[vkfs.length, hkfs.length]
      aggs_hash[hvs] = op.aggregate(aggs)
    }
    v_after = lambda {|(_, aggs)|
      vvs = aggs[0, vkfs.length]
      ary = vvs
      hvs_list.each {|hvs|
        if aggs_hash.has_key? hvs
          ary.concat(aggs_hash[hvs].last(num_aggregate_fields))
        else
          ary.concat([nil] * num_aggregate_fields)
        end
      }
      pairs = {}
      ary.each_with_index {|v, i|
        pairs[(i+1).to_s] = v
      }
      y.yield pairs
    }
    er.detect_nested_group_by(
      [[all_representative, all_before],
       [v_representative, v_before, v_after]]).each(&body)
  }
  Tb::Cmd.opt_N = true
  output_tbenum(er)
end

