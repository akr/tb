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
  op.banner = "Usage: tb cross [OPTS] HKEY-FIELD1,... VKEY-FIELD1,... [TABLE ...]\n" +
    "Create a contingency table."
  define_common_option(op, "ho", "--no-pager")
  op.def_option('-a AGGREGATION-SPEC[,NEW-FIELD]',
                '--aggregate AGGREGATION-SPEC[,NEW-FIELD]') {|arg| Tb::Cmd.opt_cross_fields << arg }
  op.def_option('-c', '--compact', 'compact format') { Tb::Cmd.opt_cross_compact = true }
  op
end

def (Tb::Cmd).main_cross(argv)
  op_cross.parse!(argv)
  exit_if_help('cross')
  err('no hkey-fields given.') if argv.empty?
  hkfs = split_field_list_argument(argv.shift)
  err('no vkey-fields given.') if argv.empty?
  vkfs = split_field_list_argument(argv.shift)
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
  Tb::CatReader.open(argv, Tb::Cmd.opt_N) {|tblreader|
    vkis = nil
    hkis = nil
    vset = {}
    hset = {}
    set = {}
    header = nil
    header_proc = lambda {|header0|
      header = header0
      vkis = vkfs.map {|f| header.index(f) }
      hkis = hkfs.map {|f| header.index(f) }
    }
    tblreader.header_and_each(header_proc) {|pairs|
      ary = header.map {|f| pairs[f] }
      vkvs = ary.values_at(*vkis)
      hkvs = ary.values_at(*hkis)
      vset[vkvs] = true if !vset.include?(vkvs)
      hset[hkvs] = true if !hset.include?(hkvs)
      if !set.include?([vkvs, hkvs])
        set[[vkvs, hkvs]] = opt_cross_fields.map {|agg_spec, nf|
          begin
            ag = make_aggregator(agg_spec, header)
          rescue ArgumentError
            err($!.message)
          end
          ag.update(ary)
          ag
        }
      else
        set[[vkvs, hkvs]].each {|ag|
          ag.update(ary)
        }
      end
    }
    vary = vset.keys.sort_by {|a| a.map {|v| smart_cmp_value(v) } }
    hary = hset.keys.sort_by {|a| a.map {|v| smart_cmp_value(v) } }
    with_output {|out|
      Tb.csv_stream_output(out) {|gen|
        hkfs.each_with_index {|hkf, i|
          next if Tb::Cmd.opt_cross_compact && i == hkfs.length - 1
          row = [nil] * (vkfs.length - 1) + [hkf]
          hary.each {|hkvs| opt_cross_fields.length.times { row << hkvs[i] } }
          gen << row
        }
        if Tb::Cmd.opt_cross_compact
          r = vkfs.dup
          hary.each {|hkvs| r.concat([hkvs[-1]] * opt_cross_fields.length) }
          gen << r
        else
          r = vkfs.dup
          hary.each {|hkvs| r.concat opt_cross_fields.map {|agg_spec, new_field| new_field } }
          gen << r
        end
        vary.each {|vkvs|
          row = vkvs.dup
          hary.each {|hkvs|
            ags = set[[vkvs, hkvs]]
            if !ags
              opt_cross_fields.length.times { row << nil }
            else
              ags.each {|ag| row << ag.finish }
            end
          }
          gen << row
        }
      }
    }
  }
end

