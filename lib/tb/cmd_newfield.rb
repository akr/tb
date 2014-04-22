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

Tb::Cmd.subcommands << 'newfield'

Tb::Cmd.default_option[:opt_newfield_ruby] = nil

def (Tb::Cmd).op_newfield
  op = OptionParser.new
  op.banner = "Usage: tb newfield [OPTS] FIELD VALUE [TABLE]\n" +
    "Add a field."
  define_common_option(op, "ho", "--no-pager")
  op.def_option('--ruby RUBY-EXP', 'ruby expression to generate values.  A hash is given as _.  no VALUE argument.') {|ruby_exp|
    Tb::Cmd.opt_newfield_ruby = ruby_exp
  }
  op
end

def (Tb::Cmd).main_newfield(argv)
  op_newfield.parse!(argv)
  exit_if_help('newfield')
  err('no new field name given.') if argv.empty?
  field = argv.shift
  if Tb::Cmd.opt_newfield_ruby
    rubyexp = Tb::Cmd.opt_newfield_ruby
    pr = eval("lambda {|_| #{rubyexp} }")
  else
    err('no ruby expression given.') if argv.empty?
    value = argv.shift
    pr = lambda {|_| value }
  end
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  er = creader.newfield(field) {|pairs| pr.call(pairs) }
  output_tbenum(er)
end


