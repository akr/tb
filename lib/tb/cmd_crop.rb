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

Tb::Cmd.subcommands << 'crop'

Tb::Cmd.default_option[:opt_crop_range] = nil

def (Tb::Cmd).op_crop
  op = OptionParser.new
  op.banner = 'Usage: tb crop [OPTS] [TABLE ...]'
  define_common_option(op, "ho", "--no-pager")
  op.def_option('-r RANGE', 'range.  i.e. "2,1-4,3", "B1:D3"') {|arg| Tb::Cmd.opt_crop_range = arg }
  op
end

def (Tb::Cmd).decode_a1_addressing_col(str)
  (26**str.length-1)/25+str.tr("A-Z", "0-9A-P").to_i(26)
end

def (Tb::Cmd).main_crop(argv)
  op_crop.parse!(argv)
  exit_if_help('crop')
  argv = ['-'] if argv.empty?
  stream = false
  if Tb::Cmd.opt_crop_range
    case Tb::Cmd.opt_crop_range
    when /\AR(\d+)C(\d+):R(\d+)C(\d+)\z/ # 1-based (R1C1 reference style)
      stream = true
      range_row1 = $1.to_i
      range_col1 = $2.to_i
      range_row2 = $3.to_i
      range_col2 = $4.to_i
    when /\A([A-Z]+)(\d+):([A-Z]+)(\d+)\z/ # 1-based (A1 reference style)
      stream = true
      range_col1 = decode_a1_addressing_col($1)
      range_row1 = $2.to_i
      range_col2 = decode_a1_addressing_col($3)
      range_row2 = $4.to_i
    else
      raise ArgumentError, "unexpected range argument: #{Tb::Cmd.opt_crop_range.inspect}"
    end
  end
  if stream
    with_table_stream_output {|gen|
      Tb::CatReader.open(argv, true) {|tblreader|
        rownum = 1
        tblreader.each {|ary|
          if range_row2 < rownum
            break
          end
          if range_row1 <= rownum
            if range_col2 < ary.length
              ary[range_col2..-1] = []
            end
            if 1 < range_col1
              ary[0...(range_col1-1)] = []
            end
            gen << ary
          end
          rownum += 1
        }
      }
    }
  else
    arys = []
    Tb::CatReader.open(argv, true) {|tblreader|
      tblreader.each {|a|
        a.pop while !a.empty? && (a.last.nil? || a.last == '')
        arys << a
      }
    }
    arys.pop while !arys.empty? && arys.last.all? {|v| v.nil? || v == '' }
    arys.shift while !arys.empty? && arys.first.all? {|v| v.nil? || v == '' }
    if !arys.empty?
      while arys.all? {|a| a.empty? || (a.first.nil? || a.first == '') }
        arys.each {|a| a.shift }
      end
    end
    with_table_stream_output {|gen|
      arys.each {|a| gen << a }
    }
  end
end

