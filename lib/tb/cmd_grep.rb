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

Tb::Cmd.subcommands << 'grep'

Tb::Cmd.default_option[:opt_grep_e] = nil
Tb::Cmd.default_option[:opt_grep_ruby] = nil
Tb::Cmd.default_option[:opt_grep_f] = nil
Tb::Cmd.default_option[:opt_grep_v] = nil

def (Tb::Cmd).op_grep
  op = OptionParser.new
  op.banner = "Usage: tb grep [OPTS] REGEXP [TABLE ...]\n" +
    "Search rows using regexp or ruby expression."
  define_common_option(op, "hNo", "--no-pager")
  op.def_option('-f FIELD', 'search field') {|field| Tb::Cmd.opt_grep_f = field }
  op.def_option('-e REGEXP', 'specify a regexp.') {|pattern| Tb::Cmd.opt_grep_e = pattern }
  op.def_option('--ruby RUBY-EXP', 'predicate written in ruby.  A hash is given as _.  no usual regexp argument.') {|ruby_exp| Tb::Cmd.opt_grep_ruby = ruby_exp }
  op.def_option('-v', 'ouput the records which doesn\'t match') { Tb::Cmd.opt_grep_v = true }
  op
end

def (Tb::Cmd).main_grep(argv)
  op_grep.parse!(argv)
  exit_if_help('grep')
  if Tb::Cmd.opt_grep_ruby
    pred = eval("lambda {|_| #{Tb::Cmd.opt_grep_ruby} }")
  elsif Tb::Cmd.opt_grep_e
    re = Regexp.new(Tb::Cmd.opt_grep_e)
    pred = Tb::Cmd.opt_grep_f ? lambda {|_| re =~ _[Tb::Cmd.opt_grep_f] } :
                                lambda {|_| _.any? {|k, v| re =~ v.to_s } }
  else
    err("no regexp given.") if argv.empty?
    re = Regexp.new(argv.shift)
    pred = Tb::Cmd.opt_grep_f ? lambda {|_| re =~ _[Tb::Cmd.opt_grep_f] } :
                                lambda {|_| _.any? {|k, v| re =~ v.to_s } }
  end
  opt_v = Tb::Cmd.opt_grep_v ? true : false
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  er = Tb::Enumerator.new {|y|
    header = nil
    creader.with_header {|header0|
      header = header0
      y.set_header header
    }.each {|pairs|
      h = {}
      pairs.each {|f, v|
        h[f] = v
      }
      found = pred.call(h)
      found = opt_v ^ !!(found)
      if found
        y.yield pairs
      end
    }
  }
  output_tbenum(er)
end

