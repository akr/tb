# Copyright (C) 2012 Tanaka Akira  <akr@fsij.org>
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

Tb::Cmd.subcommands << 'melt'

#Tb::Cmd.default_option[:opt_melt_R] = nil
#Tb::Cmd.default_option[:opt_melt_V] = nil
Tb::Cmd.default_option[:opt_melt_variable_field] = 'variable'
Tb::Cmd.default_option[:opt_melt_value_field] = 'value'

def (Tb::Cmd).op_melt
  op = OptionParser.new
  op.banner = "Usage: tb melt KEY-FIELDS-LIST [OPTS] [TABLE ...]\n" +
    "split value fields into records."
  define_common_option(op, "hNo", "--no-pager")
  #op.def_option('-R REGEXP', 'regexp for value fields') {|regexp| Tb::Cmd.opt_melt_R = regexp }
  #op.def_option('-V FIELD,...', 'value fields') {|fields| Tb::Cmd.opt_melt_V = fields }
  op.def_option('--variable-field FIELD', 'variable fields') {|field| Tb::Cmd.opt_melt_variable_field = field }
  op.def_option('--value-field FIELD', 'value field') {|field| Tb::Cmd.opt_melt_value_field = field }
  op
end

def (Tb::Cmd).main_melt(argv)
  op_melt.parse!(argv)
  exit_if_help('melt')
  err('no key-fields given.') if argv.empty?
  key_fields = split_field_list_argument(argv.shift)
  key_fields_hash = Hash[key_fields.map {|f| [f, true] }]
  argv = ['-'] if argv.empty?
  creader = Tb::CatReader.open(argv, Tb::Cmd.opt_N)
  er = Tb::Enumerator.new {|y|
    y.set_header [*key_fields, Tb::Cmd.opt_melt_variable_field, Tb::Cmd.opt_melt_value_field]
    creader.each {|pairs|
      h0 = {}
      key_fields.each {|kf|
        h0[kf] = pairs[kf]
      }
      pairs.each {|f, v|
        next if key_fields_hash[f]
        h = h0.dup
        h[Tb::Cmd.opt_melt_variable_field] = f
        h[Tb::Cmd.opt_melt_value_field] = v
        y.yield h
      }
    }
  }
  output_tbenum(er)
end

