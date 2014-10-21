# lib/tb/csv.rb - CSV related fetures for table library
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

require 'csv'

class Tb
  def Tb.csv_stream_input(input)
    csv = CSV.new(input)
    while ary = csv.shift
      yield ary
    end
    nil
  end

  def Tb.csv_stream_output(out)
    gen = Object.new
    gen.instance_variable_set(:@out, out)
    def gen.<<(ary)
      @out << ary.to_csv
    end
    yield gen
  end

  def Tb.csv_encode_row(ary)
    ary.to_csv
  end

  # :call-seq:
  #   generate_csv(out='', fields=nil) {|recordids| modified_recordids }
  #   generate_csv(out='', fields=nil)
  #
  def generate_csv(out='', fields=nil, &block)
    if fields.nil?
      fields = list_fields
    end
    recordids = list_recordids
    if block_given?
      recordids = yield(recordids)
    end
    Tb.csv_stream_output(out) {|gen|
      gen << fields
      recordids.each {|recordid|
        gen << get_values(recordid, *fields)
      }
    }
    out
  end

  class HeaderCSVReader < HeaderReader
    def initialize(io)
      aryreader = CSV.new(io)
      super lambda { aryreader.shift }
    end
  end

  class HeaderCSVWriter < HeaderWriter
    # io is an object which has "<<" method.
    def initialize(io)
      super lambda {|ary| io << ary.to_csv}
    end
  end

  class NumericCSVReader < NumericReader
    def initialize(io)
      aryreader = CSV.new(io)
      super lambda { aryreader.shift }
    end
  end

  class NumericCSVWriter < NumericWriter
    # io is an object which has "<<" method.
    def initialize(io)
      super lambda {|ary| io << ary.to_csv }
    end
  end

end
