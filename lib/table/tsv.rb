# lib/table/tsv.rb - TSV related fetures for table library
#
# Copyright (C) 2010-2011 Tanaka Akira  <akr@fsij.org>
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

require 'stringio'

class Table

  def Table.load_tsv(filename, *header_fields, &block)
    Table.parse_tsv(File.read(filename), *header_fields, &block)
  end

  def Table.parse_tsv(tsv, *header_fields)
    aa = []
    tsv_stream_input(tsv) {|ary|
      aa << ary
    }
    aa = yield aa if block_given?
    if header_fields.empty?
      reader = Table::Reader.new(aa)
      arys = []
      reader.each {|ary|
        arys << ary
      }
      header = reader.header
    else
      header = header_fields
      arys = aa
    end
    t = Table.new(header)
    arys.each {|ary|
      ary << nil while ary.length < header.length
      t.insert_values header, ary
    }
    t
  end

  def Table.tsv_stream_input(tsv)
    tsvreader = TSVReader.new(tsv)
    while ary = tsvreader.shift
      yield ary
    end
    nil
  end

  class TSVReader
    def initialize(input)
      if input.respond_to? :to_str
        @input = StringIO.new(input)
      else
        @input = input
      end
    end

    def shift
      line = @input.gets
      return nil if !line
      line = line.chomp("\n")
      line = line.chomp("\r")
      line.split(/\t/, -1)
    end

    def close
      @input.close
    end
  end

  def Table.tsv_stream_output(out)
    gen = Object.new
    gen.instance_variable_set(:@out, out)
    def gen.<<(ary)
      @out << Table.tsv_fields_join(ary) << "\n"
    end
    yield gen
  end

  # :call-seq:
  #   generate_tsv(out='', fields=nil) {|recordids| modified_recordids }
  #   generate_tsv(out='', fields=nil)
  #
  def generate_tsv(out='', fields=nil, &block)
    if fields.nil?
      fields = list_fields
    end
    recordids = list_recordids
    if block_given?
      recordids = yield(recordids)
    end
    Table.tsv_stream_output(out) {|gen|
      gen << fields
      recordids.each {|recordid|
        gen << get_values(recordid, *fields)
      }
    }
    out
  end

  def Table.tsv_fields_join(values)
    values.map {|v| v.to_s.gsub(/[\t\r\n]/, ' ') }.join("\t")
  end
end
