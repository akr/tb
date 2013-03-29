# lib/tb/ltsv.rb - LTSV related fetures for table library
#
# Copyright (C) 2013 Tanaka Akira  <akr@fsij.org>
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
  def Tb.load_ltsv(filename, &block)
    Tb.parse_ltsv(File.read(filename), &block)
  end

  def Tb.parse_ltsv(ltsv)
    assoc_list = []
    ltsv_stream_input(ltsv) {|assoc|
      assoc_list << assoc
    }
    fields_hash = {}
    assoc_list.each {|assoc|
      assoc.each {|key, val|
        fields_hash[key] ||= fields_hash.size
      }
    }
    header = fields_hash.keys
    t = Tb.new(header)
    assoc_list.each {|assoc|
      t.insert Hash[assoc]
    }
    t
  end

  def Tb.ltsv_stream_input(ltsv)
    ltsvreader = LTSVReader.new(ltsv)
    while assoc = ltsvreader.shift
      yield assoc
    end
    nil
  end

  def Tb.ltsv_escape_string(str)
    if /[\0-\x1f":\\\x7f]/ =~ str
      '"' + 
      str.gsub(/[\0-\x1f":\\\x7f]/) {
        ch = $&
        case ch
        when "\0"; '\0'
        when "\a"; '\a'
        when "\b"; '\b'
        when "\f"; '\f'
        when "\n"; '\n'
        when "\r"; '\r'
        when "\t"; '\t'
        when "\v"; '\v'
        when "\e"; '\e'
        else
          "\\x%02X" % ch.ord
        end
      } +
      '"'
    else
      str
    end
  end

  def Tb.ltsv_unescape_string(str)
    if /\A\s*"(.*)"\s*\z/ =~ str
      $1.gsub(/\\([0abfnrtve]|x([0-9A-Fa-f][0-9A-Fa-f]))/) {
        if $2
          [$2.to_i].pack("H2")
        else
          case $1
          when "0"; "\0"
          when "a"; "\a"
          when "b"; "\b"
          when "f"; "\f"
          when "n"; "\n"
          when "r"; "\r"
          when "t"; "\t"
          when "v"; "\v"
          when "e"; "\e"
          else
            raise "[bug] unexpected escape"
          end
        end
      }
    else
      str
    end
  end

  class LTSVReader
    include Tb::Enumerable

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
      ary = line.split(/\t/, -1)
      assoc = ary.map {|str|
        /:/ =~ str
        key = $`
        val = $'
        key = Tb.ltsv_unescape_string(key)
        val = Tb.ltsv_unescape_string(val)
        [key, val]
      }
      assoc
    end

    def header_and_each(header_proc)
      header_proc.call(nil) if header_proc
      while assoc = self.shift
        yield Hash[assoc]
      end
    end

    def each(&block)
      header_and_each(nil, &block)
    end
  end

  def Tb.ltsv_stream_output(out)
    gen = Object.new
    gen.instance_variable_set(:@out, out)
    def gen.<<(assoc)
      @out << Tb.ltsv_assoc_join(assoc) << "\n"
    end
    yield gen
  end

  # :call-seq:
  #   generate_ltsv(out='') {|recordids| modified_recordids }
  #   generate_ltsv(out='')
  #
  def generate_ltsv(out='', fields=nil, &block)
    recordids = list_recordids
    if block_given?
      recordids = yield(recordids)
    end
    Tb.ltsv_stream_output(out) {|gen|
      recordids.each {|recordid|
        gen << get_record(recordid)
      }
    }
    out
  end

  def Tb.ltsv_assoc_join(assoc)
    assoc.map {|key, val|
      Tb.ltsv_escape_string(key) + ':' + Tb.ltsv_escape_string(val)
    }.join("\t")
  end
end
