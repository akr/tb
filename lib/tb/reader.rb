# lib/tb/reader.rb - Tb::Reader class
#
# Copyright (C) 2011-2012 Tanaka Akira  <akr@fsij.org>
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

class Tb::Reader
  include Tb::Enum

  def initialize(opts={}, &rawreader_open)
    @opt_n = opts[:numeric]
    @reader_open = rawreader_open
    @fieldset = nil
  end

  def internal_header(rawreader)
    return @fieldset.header if @fieldset
    if @opt_n
      @fieldset = Tb::FieldSet.new
    else
      while ary = rawreader.shift
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
    raise TypeError if !@fieldset
    @fieldset.index_from_field_ex(f)
  end

  def index_from_field(f)
    raise TypeError if !@fieldset
    @fieldset.index_from_field(f)
  end

  def field_from_index_ex(i)
    raise TypeError if !@fieldset
    raise ArgumentError, "negative index: #{i}" if i < 0
    @fieldset.field_from_index_ex(i)
  end

  def field_from_index(i)
    raise TypeError if !@fieldset
    raise ArgumentError, "negative index: #{i}" if i < 0
    @fieldset.field_from_index(i)
  end

  def internal_shift(rawreader)
    raise TypeError if !@fieldset
    ary = rawreader.shift
    field_from_index_ex(ary.length-1) if ary && !ary.empty?
    ary
  end

  def header_and_each(header_proc)
    body = lambda {|rawreader|
      h = self.internal_header(rawreader)
      header_proc.call(h) if header_proc
      while ary = self.internal_shift(rawreader)
        pairs = []
        ary.each_with_index {|v, i|
          f = field_from_index_ex(i)
          pairs << [f, v]
        }
        yield Tb::Pairs.new(pairs)
      end
    }
    @reader_open.call(body)
  end

  def each(&block)
    header_and_each(nil, &block)
  end
end
