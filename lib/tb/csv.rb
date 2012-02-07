# lib/tb/csv.rb - CSV related fetures for table library
#
# Copyright (C) 2010-2012 Tanaka Akira  <akr@fsij.org>
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
  def Tb.load_csv(filename, *header_fields, &block)
    Tb.parse_csv(File.read(filename), *header_fields, &block)
  end

  def Tb.parse_csv(csv, *header_fields)
    aa = []
    csv_stream_input(csv) {|ary|
      aa << ary
    }
    aa = yield aa if block_given?
    if header_fields.empty?
      reader = Tb::Reader.new {|body| body.call(aa) }
      reader.to_tb
    else
      header = header_fields
      arys = aa
      t = Tb.new(header)
      arys.each {|ary|
        ary << nil while ary.length < header.length
        t.insert_values header, ary
      }
      t
    end
  end

  def Tb.csv_stream_input(csv, &b)
    csvreader = CSVReader.new(csv)
    csvreader.each(&b)
    nil
  end

  class CSVReader
    def initialize(input)
      @csv = CSV.new(input)
    end

    def shift
      @csv.shift
    end

    def each
      while ary = self.shift
        yield ary
      end
      nil
    end
  end

  def Tb.csv_stream_output(out)
    require 'csv'
    gen = Object.new
    gen.instance_variable_set(:@out, out)
    def gen.<<(ary)
      @out << ary.to_csv
    end
    yield gen
  end

  def Tb.csv_encode_row(ary)
    require 'csv'
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
    require 'csv'
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
end
