# lib/tb/reader.rb - Tb::Reader class
#
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
      reader = Tb::Reader.new(aa)
      arys = []
      reader.each {|ary|
        arys << ary
      }
      header = reader.header
    else
      header = header_fields
      arys = aa
    end
    t = Tb.new(header)
    arys.each {|ary|
      ary << nil while ary.length < header.length
      t.insert_values header, ary
    }
    t
  end

  def Tb.load_tsv(filename, *header_fields, &block)
    Tb.parse_tsv(File.read(filename), *header_fields, &block)
  end

  def Tb.parse_tsv(tsv, *header_fields)
    aa = []
    tsv_stream_input(tsv) {|ary|
      aa << ary 
    }
    aa = yield aa if block_given?
    if header_fields.empty?
      reader = Tb::Reader.new(aa)
      arys = []
      reader.each {|ary|
        arys << ary
      }
      header = reader.header
    else
      header = header_fields
      arys = aa
    end
    t = Tb.new(header)
    arys.each {|ary|
      ary << nil while ary.length < header.length
      t.insert_values header, ary
    }
    t
  end
end

class Tb::Reader
  def self.open(filename, opts={})
    io = nil
    case filename
    when /\Acsv:/
      io = File.open($')
      rawreader = Tb::CSVReader.new(io)
    when /\Atsv:/
      io = File.open($')
      rawreader = Tb::TSVReader.new(io)
    when /\.csv\z/
      io = File.open(filename)
      rawreader = Tb::CSVReader.new(io)
    when /\.tsv\z/
      io = File.open(filename)
      rawreader = Tb::TSVReader.new(io)
    else
      if filename == '-'
        rawreader = Tb::CSVReader.new(STDIN)
      else
        # guess table format?
        io = File.open(filename)
        rawreader = Tb::CSVReader.new(io)
      end
    end
    reader = self.new(rawreader, opts)
    if block_given?
      begin
        yield reader
      ensure
        reader.close
      end
    else
      reader
    end
  end

  def initialize(rawreader, opts={})
    @opt_n = opts[:numeric]
    @reader = rawreader
    @fieldset = nil
  end

  def header
    return @fieldset.header if @fieldset
    if @opt_n
      @fieldset = Tb::FieldSet.new
    else
      while ary = @reader.shift
        if ary.all? {|elt| elt.nil? || elt == '' }
          next
        else
          @fieldset = Tb::FieldSet.new(*ary)
          return @fieldset.header
        end
      end
      @fieldset = Tb::FieldSet.new
    end
    return @fieldset.header
  end

  def index_from_field_ex(f)
    self.header
    @fieldset.index_from_field_ex(f)
  end

  def index_from_field(f)
    self.header
    @fieldset.index_from_field(f)
  end

  def field_from_index_ex(i)
    raise ArgumentError, "negative index: #{i}" if i < 0
    self.header
    @fieldset.field_from_index_ex(i)
  end

  def field_from_index(i)
    raise ArgumentError, "negative index: #{i}" if i < 0
    self.header
    @fieldset.field_from_index(i)
  end

  def shift
    header
    ary = @reader.shift
    field_from_index_ex(ary.length-1) if ary && !ary.empty?
    ary
  end

  def each
    while ary = self.shift
      yield ary
    end
    nil
  end

  def close
    @reader.close
  end
end
