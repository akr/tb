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

Tb::Cmd.subcommands << 'shape'

def (Tb::Cmd).op_shape
  op = OptionParser.new
  op.banner = "Usage: tb shape [OPTS] [TABLE ...]\n" +
    "Show table size."
  define_common_option(op, "hNo", "--no-pager")
  op
end

Tb::Cmd.def_vhelp('shape', <<'End')
Example:

  % cat tst.csv
  foo,bar,baz
  1,2,3
  4,5
  6,7,8,9
  % tb shape tst.csv -o json:-
  [
  {
    "filename": "tst.csv",
    "records": 3,
    "min_pairs": 2,
    "max_pairs": 3,
    "header_fields": 3,
    "min_fields": 2,
    "max_fields": 4
  }
  ]
End

def (Tb::Cmd).main_shape(argv)
  op_shape.parse!(argv)
  exit_if_help('shape')
  filenames = argv.empty? ? ['-'] : argv
  ter = Tb::Enumerator.new {|y|
    filenames.each {|filename|
      tablereader_open(filename) {|tblreader|
        tblreader.enable_warning = false if tblreader.respond_to? :enable_warning
        num_records = 0
        num_header_fields = nil
        min_num_fields = nil
        max_num_fields = nil
        if tblreader.respond_to? :header_array_hook
          tblreader.header_array_hook = lambda {|header|
            num_header_fields = header.length
          }
        end
        if tblreader.respond_to? :row_array_hook
          tblreader.row_array_hook = lambda {|ary|
            n = ary.length
            if min_num_fields.nil?
              min_num_fields = max_num_fields = n
            else
              min_num_fields = n if n < min_num_fields
              max_num_fields = n if max_num_fields < n
            end
          }
        end
        min_num_pairs = nil
        max_num_pairs = nil
        tblreader.each {|pairs|
          num_records += 1
          n = pairs.length
          if min_num_pairs.nil?
            min_num_pairs = max_num_pairs = n
          else
            min_num_pairs = n if n < min_num_pairs
            max_num_pairs = n if max_num_pairs < n
          end
        }
        h = {
          'filename'=>filename,
          'records'=>num_records,
          'min_pairs'=>min_num_pairs,
          'max_pairs'=>max_num_pairs,
        }
        h['header_fields'] = num_header_fields if num_header_fields
        h['min_fields'] = min_num_fields if min_num_fields
        h['max_fields'] = max_num_fields if max_num_fields
        y.yield(h)
      }
    }
  }
  Tb::Cmd.opt_N = false
  output_tbenum(ter)
end

