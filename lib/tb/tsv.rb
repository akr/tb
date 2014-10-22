# lib/tb/tsv.rb - TSV related fetures for table library
#
# Copyright (C) 2010-2014 Tanaka Akira  <akr@fsij.org>
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

require 'stringio'

class Tb
  def Tb.tsv_fields_join(values)
    values.map {|v| v.to_s.gsub(/[\t\r\n]/, ' ') }.join("\t")+ "\n"
  end

  def Tb.tsv_fields_split(line)
    line = line.chomp("\n")
    line = line.chomp("\r")
    line.split(/\t/, -1)
  end

  class HeaderTSVReader < HeaderReader
    def initialize(io)
      super lambda {
        line = io.gets
        if line
          Tb.tsv_fields_split(line)
        else
          nil
        end
      }
    end
  end

  class HeaderTSVWriter < HeaderWriter
    # io is an object which has "<<" method.
    def initialize(io)
      super lambda {|ary|
        io << Tb.tsv_fields_join(ary)
      }
    end
  end

  class NumericTSVReader < NumericReader
    def initialize(io)
      super lambda {
        line = io.gets
        if line
          Tb.tsv_fields_split(line)
        else
          nil
        end
      }
    end
  end

  class NumericTSVWriter < NumericWriter
    def initialize(io)
      super lambda {|ary|
        io << Tb.tsv_fields_join(ary)
      }
    end
  end
end
