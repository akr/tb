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

Tb::Cmd.subcommands << 'crop'

Tb::Cmd.default_option[:opt_crop_range] = nil

def (Tb::Cmd).op_crop
  op = OptionParser.new
  op.banner = "Usage: tb crop [OPTS] [TABLE ...]\n" +
    "Extract rectangle in a table."
  define_common_option(op, "ho", "--no-pager")
  op.def_option('-r RANGE', 'range.  i.e. "R2C1:R4C3", "B1:D3"') {|arg| Tb::Cmd.opt_crop_range = arg }
  op
end

Tb::Cmd.def_vhelp('crop', <<'End')
Example:

  % cat tst.csv
  0,1,2,4
  5,6,7,8
  9,a,b,c
  d,e,f,g
  h,i,j,k
  % tb crop -r R2C2:R4C3 tst.csv
  6,7
  a,b
  e,f
End


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
    creader = Tb::CatReader.open(argv, true)
    er = Tb::Enumerator.new {|y|
      rownum = 1
      creader.each {|pairs|
        if range_row2 < rownum
          break
        end
        if range_row1 <= rownum
          pairs2 = pairs.reject {|f, v|
            f = f.to_i
            f < range_col1 || range_col2 < f
          }
          pairs2 = pairs2.map {|f, v|
            [(f.to_i - range_col1 + 1).to_s, v]
          }
          y.yield Hash[pairs2]
        end
        rownum += 1
      }
    }
    Tb::Cmd.opt_N = true
    output_tbenum(er)
  else
    creader = Tb::CatReader.open(argv, true)
    last_nonempty_row = nil
    lmargin_min = nil
    ter = Enumerator.new {|y|
      numrows = 0
      creader.each {|pairs|
        ary = []
        pairs.each {|f, v|
          ary[f.to_i-1] = v
        }
        while !ary.empty? && (ary.last.nil? || ary.last == '')
          ary.pop
        end
        if numrows == 0 && ary.empty?
          next
        end
        if !ary.empty?
          lmargin = 0
          while lmargin < ary.length
            if !ary[lmargin].nil? && ary[lmargin] != ''
              break
            end
            lmargin += 1
          end
          if lmargin_min.nil? || lmargin < lmargin_min
            lmargin_min = lmargin
          end
        end
        last_nonempty_row = numrows if !ary.empty?
        y.yield ary
        numrows += 1
      }
    }.to_fileenumerator
    er = Tb::Enumerator.new {|y|
      ter.each_with_index {|ary, rownum|
        if last_nonempty_row < rownum
          break
        end
        ary.slice!(0, lmargin_min)
        pairs = Hash[ary.map.with_index {|v, i| ["#{i+1}", v]}]
        y.yield pairs
      }
    }
    Tb::Cmd.opt_N = true
    output_tbenum(er)
  end
end

