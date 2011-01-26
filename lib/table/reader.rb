# lib/table/reader.rb - Table::Reader class
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

class Table::Reader
  def self.open(filename, opts={})
    io = nil
    case filename
    when /\.csv\z/
      io = File.open(filename)
      rawreader = Table::CSVReader.new(io)
    when /\.tsv\z/
      io = File.open(filename)
      rawreader = Table::TSVReader.new(io)
    else
      if filename == '-'
        rawreader = Table::CSVReader.new(STDIN)
      else
        # guess table format?
        io = File.open(filename)
        rawreader = Table::CSVReader.new(io)
      end
    end
    self.new(rawreader, opts)
  end

  def initialize(rawreader, opts={})
    @opt_n = opts[:numeric]
    @reader = rawreader
    @header = nil
  end

  def header
    return @header if @header
    return @header = [] if @opt_n
    while ary = @reader.shift
      if ary.all? {|elt| elt.nil? || elt == '' }
        next
      else
        @header = fix_header(ary)
        return @header
      end
    end
    @header = []
    return @header
  end

  def index_from_field(f)
    if @opt_n
      raise "numeric field start from 1: #{f.inspect}" if /\A0+\z/ =~ f
      raise "numeric field name expected: #{f.inspect}" if /\A(\d+)\z/ !~ f
      $1.to_i - 1
    else
      i = self.header.index(f)
      if i.nil?
        raise ArgumentError, "unexpected field name: #{f.inspect}"
      end
      i
    end
  end

  def field_from_index(i)
    raise ArgumentError, "negative index: #{i}" if i < 0
    self.header
    f = @header[i]
    return f if f
    if @opt_n
      while @header.length <= i
        @header << "#{@header.length+1}"
      end
      @header[i]
    else
      h = {}
      @header.each {|ff| h[ff] = true if /\A\(\d+\)\z/ =~ ff }
      n = 1
      while @header.length <= i
        while h[f = "(#{n})"]
          n += 1
        end
        @header << f
      end
      @header[i]
    end
  end

  def shift
    header
    ary = @reader.shift
    field_from_index(ary.length-1) if ary && !ary.empty?
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
    @io.close
  end

  def fix_header(header)
    h = {}
    header.map {|s|
      s ||= ''
      if h[s]
        s += "(2)" if /\(\d+\)\z/ !~ s
        while h[s]
          s = s.sub(/\((\d+)\)\z/) { n = $1.to_i; "(#{n+1})" }
        end
        s
      end
      h[s] = true
      s
    }
  end
end
