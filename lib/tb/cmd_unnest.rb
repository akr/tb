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

Tb::Cmd.subcommands << 'unnest'

Tb::Cmd.default_option[:opt_unnest_prefix] = ''
Tb::Cmd.default_option[:opt_unnest_outer] = nil

def (Tb::Cmd).op_unnest
  op = OptionParser.new
  op.banner = "Usage: tb unnest [OPTS] FIELD [TABLE ...]\n" +
    "Unnest a field."
  define_common_option(op, "hNo", "--no-pager")
  op.def_option('--prefix PREFIX', 'field prefix') {|prefix| Tb::Cmd.opt_unnest_prefix = prefix }
  op.def_option('--outer', 'retain rows for empty nested table') { Tb::Cmd.opt_unnest_outer = true }
  op
end

def (Tb::Cmd).main_unnest(argv)
  op_unnest.parse!(argv)
  exit_if_help('unnest')
  err('no field given.') if argv.empty?
  target_field = argv.shift
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  er = Tb::Enumerator.new {|y|
    tbl = creader.to_tb
    if !tbl.list_fields.include?(target_field)
      err("field not found: #{target_field.inspect}")
    end
    nested_fields = []
    tbl.each {|rec|
      v = rec[target_field]
      if v
        nested_fields |= Tb.parse_csv(v).list_fields
      end
    }
    if Tb::Cmd.opt_unnest_prefix
      nested_fields.map! {|f| Tb::Cmd.opt_unnest_prefix + f }
    end
    result_fields = tbl.list_fields.map {|f|
      if f == target_field
        nested_fields.map {|nf|
          Tb::Cmd.opt_unnest_prefix + nf
        }
      else
        f
      end
    }.flatten
    y.set_header result_fields
    tbl.each {|rec|
      if rec[target_field]
        ntbl = Tb.parse_csv(rec[target_field])
      end
      if ntbl && 0 < ntbl.size
        ntbl.each {|nrec|
          ary = []
          tbl.list_fields.each {|f|
            if f == target_field
              nested_fields.each {|nf|
                ary << nrec[nf]
              }
            else
              ary << rec[f]
            end
          }
          y.yield Tb::Pairs.new(result_fields.zip(ary))
        }
      elsif Tb::Cmd.opt_unnest_outer
        ary = []
        tbl.list_fields.each {|f|
          if f == target_field
            nested_fields.each {|nf|
              ary << nil
            }
          else
            ary << rec[f]
          end
        }
        y.yield Tb::Pairs.new(result_fields.zip(ary))
      end
    }
  }
  with_output {|out|
    er.write_to_csv_to_io(out, !Tb::Cmd.opt_N)
  }
end

