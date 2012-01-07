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

Tb::Cmd.subcommands << 'nest'

def (Tb::Cmd).op_nest
  op = OptionParser.new
  op.banner = "Usage: tb nest [OPTS] NEWFIELD,OLDFIELD1,OLDFIELD2,... [TABLE ...]\n" +
    "Nest fields."
  define_common_option(op, "hNo", "--no-pager")
  op
end

def (Tb::Cmd).main_nest(argv)
  op_nest.parse!(argv)
  exit_if_help('nest')
  err('no fields given.') if argv.empty?
  fields = split_field_list_argument(argv.shift)
  newfield, *oldfields = fields
  oldfields_hash = {}
  oldfields.each {|f| oldfields_hash[f] = true }
  argv = ['-'] if argv.empty?
  tbl = Tb::CatReader.open(argv, Tb::Cmd.opt_N) {|tblreader| build_table(tblreader) }
  oldfields.each {|f|
    if !tbl.list_fields.include?(f)
      err("field not found: #{f.inspect}")
    end
  }
  result_fields = []
  tbl.list_fields.each {|f|
    if !oldfields_hash.include?(f)
      result_fields << f
    end
  }
  result_fields << newfield
  h = {}
  tbl.each {|rec|
    k = []
    v = []
    tbl.list_fields.each {|f|
      if oldfields_hash.include? f
        v << rec[f]
      else
        k << rec[f]
      end
    }
    if !h[k]
      h[k] = [h.size, []]
    end
    h[k][1] << v
  }
  with_table_stream_output {|gen|
    gen.output_header result_fields
    h.keys.sort_by {|k| h[k][0] }.each {|k|
      vs = h[k][1]
      Tb.csv_stream_output(nested_csv="") {|ngen|
        ngen << oldfields
        vs.each {|v|
          ngen << v
        }
      }
      ary = []
      ary.concat k
      ary << nested_csv
      gen << ary
    }
  }
end

