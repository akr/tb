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

def (Tb::Cmd).main_cross(argv)
  op_cross.parse!(argv)
  exit_if_help('cross')
  err('no vkey-fields given.') if argv.empty?
  vkfs = split_field_list_argument(argv.shift)
  err('no hkey-fields given.') if argv.empty?
  hkfs = split_field_list_argument(argv.shift)
  if Tb::Cmd.opt_cross_fields.empty?
    opt_cross_fields = [['count', 'count']]
  else
    opt_cross_fields = Tb::Cmd.opt_cross_fields.map {|arg|
      agg_spec, new_field = split_field_list_argument(arg)
      new_field ||= agg_spec
      [agg_spec, new_field]
    }
  end
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  er = Tb::Enumerator.new {|y|
    header = nil
    hvs_hash = {}
    hvs_list = nil
    sorted = creader.extsort_by {|pairs|
      hvs = hkfs.map {|f| pairs[f] }
      hvs_hash[hvs] = true
      vcv = vkfs.map {|f| smart_cmp_value(pairs[f]) }
      vcv
    }
    sorted2 = sorted.with_header {|header0|
      header = header0
      (vkfs + hkfs).each {|f|
        if !header0.include?(f)
          err("field not found: #{f}")
        end
      }
      hvs_list = hvs_hash.keys.sort_by {|hvs| hvs.map {|hv| smart_cmp_value(hv) } }
      n = vkfs.length + hvs_list.length * opt_cross_fields.length
      header1 = (1..n).map {|i| i.to_s }
      y.set_header header1
      hkfs.each_with_index {|hkf, i|
        next if Tb::Cmd.opt_cross_compact && i == hkfs.length - 1
        h1 = {}
        j = vkfs.length
        h1[j.to_s] = hkf
        hvs_list.each {|hkvs|
          opt_cross_fields.length.times {
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
        opt_cross_fields.each {|agg_spec, new_field|
          j += 1
          if Tb::Cmd.opt_cross_compact
            h2[j.to_s] = hkvs[-1]
          else
            h2[j.to_s] = new_field
          end
        }
      }
      y.yield h2
    }
    boudary_p = lambda {|pairs1, pairs2|
      vcv1 = vkfs.map {|f| smart_cmp_value(pairs1[f]) }
      vcv2 = vkfs.map {|f| smart_cmp_value(pairs2[f]) }
      vcv1 != vcv2
    }
    aggs = nil
    before = lambda {|_|
      aggs = {}
    }
    body = lambda {|pairs|
      hvs = hkfs.map {|f| pairs[f] }
      if !aggs.has_key?(hvs)
        aggs[hvs] = opt_cross_fields.map {|agg_spec, nf|
          begin
            make_aggregator(agg_spec, header)
          rescue ArgumentError
            err($!.message)
          end
        }
      end
      ary = header.map {|f| pairs[f] }
      aggs[hvs].each {|agg|
        agg.update(ary)
      }
    }
    after = lambda {|last_pairs|
      ary = vkfs.map {|f| last_pairs[f] }
      hvs_list.each {|hvs|
        if aggs.has_key? hvs
          ary.concat(aggs[hvs].map {|agg| agg.finish })
        else
          ary.concat([nil] * opt_cross_fields.length)
        end
      }
      pairs = {}
      ary.each_with_index {|v, i|
        pairs[(i+1).to_s] = v
      }
      y.yield pairs
    }
    sorted2.each_group_element(boudary_p, before, body, after)
  }
  with_output {|out|
    er.write_to_csv(out, false)
  }
end

