# Copyright (C) 2011 Tanaka Akira  <akr@fsij.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

Tb::Cmd.subcommands << 'to-json'

def (Tb::Cmd).op_to_json
  op = OptionParser.new
  op.banner = "Usage: tb to-json [OPTS] [TABLE]\n" +
    "Convert a table to JSON (JavaScript Object Notation)."
  define_common_option(op, "hNo", "--no-pager")
  op
end

def (Tb::Cmd).main_to_json(argv)
  require 'json'
  op_to_json.parse!(argv)
  exit_if_help('to-json')
  argv = ['-'] if argv.empty?
  with_output {|out|
    out.print "["
    sep = nil
    argv.each {|filename|
      sep = ",\n\n" if sep
      tablereader_open(filename) {|tblreader|
        tblreader.each {|ary|
          out.print sep if sep
          header = tblreader.header
          h = {}
          ary.each_with_index {|e, i|
            h[header[i]] = e if !e.nil?
          }
          out.print JSON.pretty_generate(h)
          sep = ",\n"
        }
      }
    }
    out.puts "]"
  }
end

