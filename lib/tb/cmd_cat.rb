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

Tb::Cmd.subcommands << 'cat'

def (Tb::Cmd).op_cat
  op = OptionParser.new
  op.banner = 'Usage: tb cat [OPTS] [TABLE ...]'
  define_common_option(op, "hNo", "--no-pager")
  op
end

Tb::Cmd.def_vhelp('cat', <<'End')
Example:

  % cat tst1.csv 
  a,b,c
  0,1,2
  4,5,6
  % cat tst2.csv 
  a,b,d
  U,V,W
  X,Y,Z
  % tb cat tst1.csv tst2.csv
  a,b,c,d
  0,1,2
  4,5,6
  U,V,,W
  X,Y,,Z
End

def (Tb::Cmd).main_cat(argv)
  op_cat.parse!(argv)
  return show_help('cat') if 0 < Tb::Cmd.opt_help
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  header = creader.header
  with_table_stream_output {|gen|
    gen << header if !Tb::Cmd.opt_N
    creader.each {|ary|
      gen << ary
    }
  }
  true
end
