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

Tb::Cmd.subcommands << 'pp'

def (Tb::Cmd).op_pp
  op = OptionParser.new
  op.banner = 'Usage: tb pp [OPTS] [TABLE]'
  define_common_option(op, "hNo", "--no-pager")
  op
end

def (Tb::Cmd).main_pp(argv)
  op_pp.parse!(argv)
  exit_if_help('pp')
  argv.unshift '-' if argv.empty?
  with_output {|out|
    argv.each {|filename|
      tablereader_open(filename) {|tblreader|
        tblreader.each {|ary|
          a = []
          ary.each_with_index {|v, i|
            next if v.nil?
            a << [tblreader.field_from_index_ex(i), v]
          }
          q = PP.new(out, 79)
          q.guard_inspect_key {
            q.group(1, '{', '}') {
              q.seplist(a, nil, :each) {|kv|
                k, v = kv
                q.group {
                  q.pp k
                  q.text '=>'
                  q.group(1) {
                    q.breakable ''
                    q.pp v
                  }
                }
              }
            }
          }
          q.flush
          out << "\n"
        }
      }
    }
  }
  true
end

