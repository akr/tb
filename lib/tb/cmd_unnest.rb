# Copyright (C) 2011-2014 Tanaka Akira  <akr@fsij.org>
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

Tb::Cmd.def_vhelp('unnest', <<'End')
Example:

  % cat tst.csv
  author,item
  A,"name,length
  foo,3
  bar,5
  "
  B,"name,length
  baz,2
  qux,8
  "
  % tb unnest item tst.csv
  author,name,length
  A,foo,3
  A,bar,5
  B,baz,2
  B,qux,8
End

def (Tb::Cmd).main_unnest(argv)
  op_unnest.parse!(argv)
  exit_if_help('unnest')
  err('no field given.') if argv.empty?
  target_field = argv.shift
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  er = Tb::Enumerator.new {|y|
    nested_fields = {}
    ter = Tb::Enumerator.new {|y2|
      creader.with_header {|header0|
        unless header0.include? target_field
          err("field not found: #{target_field.inspect}")
        end
        y2.set_header header0
      }.each {|pairs|
        pairs2 = {}
        pairs.each {|f, v|
          if f != target_field
            pairs2[f] = v
          elsif v.nil?
            pairs2[f] = v
          else
            aa = CSV.parse(v)
            reader = Tb::HeaderReader.new(lambda { aa.shift })
            nested_tbl_rows = reader.to_a
            nested_tbl_header = reader.get_named_header
            nested_tbl_header.each {|f2|
              unless nested_fields.has_key? f2
                nested_fields[f2] = nested_fields.size
              end
            }
            pairs2[f] = [nested_tbl_header, nested_tbl_rows]
          end
        }
        y2.yield pairs2
      }
    }.to_fileenumerator
    nested_fields_ary = nested_fields.keys
    if Tb::Cmd.opt_unnest_prefix
      nested_fields_ary.map! {|f| Tb::Cmd.opt_unnest_prefix + f }
    end
    ter.with_header {|header0|
      header2 = []
      header0.each {|f|
        if f != target_field
          header2 << f
        else
          header2.concat nested_fields_ary
        end
      }
      y.set_header header2
    }.each {|pairs|
      pairs2 = {}
      pairs.each {|f, v| pairs2[f] = v if f != target_field }
      ntbl_header, ntbl_rows = pairs[target_field]
      if ntbl_header.nil? || ntbl_rows.empty?
        if Tb::Cmd.opt_unnest_outer
          y.yield pairs2
        end
      else
        ntbl_rows.each {|npairs|
          pairs3 = pairs2.dup
          npairs.each {|nf, nv|
            if Tb::Cmd.opt_unnest_prefix
              nf = Tb::Cmd.opt_unnest_prefix + nf
            end
            pairs3[nf] = nv
          }
          y.yield pairs3
        }
      end
    }
  }
  output_tbenum(er)
end

