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

Tb::Cmd.subcommands << 'grep'

$opt_grep_e = nil
$opt_grep_ruby = nil
$opt_grep_f = nil
$opt_grep_v = nil
def (Tb::Cmd).op_grep
  op = OptionParser.new
  op.banner = 'Usage: tb grep [OPTS] REGEXP [TABLE]'
  op.def_option('-h', 'show help message') { puts op; exit 0 }
  op.def_option('-N', 'use numeric field name') { $opt_N = true }
  op.def_option('-f FIELD', 'search field') {|field| $opt_grep_f = field }
  op.def_option('-e REGEXP', 'predicate written in ruby.  A hash is given as _.  no usual regexp argument.') {|pattern| $opt_grep_e = pattern }
  op.def_option('--ruby RUBY-EXP', 'specify a regexp.  no usual regexp argument.') {|ruby_exp| $opt_grep_ruby = ruby_exp }
  op.def_option('-v', 'ouput the records which doesn\'t match') { $opt_grep_v = true }
  op.def_option('--no-pager', 'don\'t use pager') { $opt_no_pager = true }
  op
end

def (Tb::Cmd).main_grep(argv)
  op_grep.parse!(argv)
  if $opt_grep_ruby
    pred = eval("lambda {|_| #{$opt_grep_ruby} }")
  elsif $opt_grep_e
    re = Regexp.new($opt_grep_e)
    pred = $opt_grep_f ? lambda {|_| re =~ _[$opt_grep_f] } :
                         lambda {|_| _.any? {|k, v| re =~ v.to_s } }
  else
    re = Regexp.new(argv.shift)
    pred = $opt_grep_f ? lambda {|_| re =~ _[$opt_grep_f] } :
                         lambda {|_| _.any? {|k, v| re =~ v.to_s } }
  end
  opt_v = $opt_grep_v ? true : false
  argv.unshift '-' if argv.empty?
  argv.each {|filename|
    tablereader_open(filename) {|tblreader|
      with_table_stream_output {|gen|
        gen.output_header tblreader.header
        tblreader.each {|ary|
          h = {}
          ary.each_with_index {|str, i|
            f = tblreader.field_from_index_ex(i)
            h[f] = str
          }
          found = pred.call(h)
          found = opt_v ^ !!(found)
          gen << ary if found
        }
      }
    }
  }
end

