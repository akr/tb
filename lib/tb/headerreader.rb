# lib/tb/headerreaderm.rb - reader mixin for table with header
#
# Copyright (C) 2014 Tanaka Akira  <akr@fsij.org>
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

class Tb
  class HeaderReader
    include Tb::Enumerable

    def initialize(get_array)
      @get_array = get_array
    end

    def header_known?
      true
    end

    def read_header_once
      return if defined? @header
      begin
        @header = @get_array.call
      end while @header && @header.all? {|elt| elt.nil? || elt == '' }
      if !@header
        @header = []
      end
      @fieldset = Tb::FieldSet.new(*@header)
    end
    private :read_header_once

    def get_named_header
      read_header_once
      @header
    end

    def get_hash
      read_header_once
      ary = @get_array.call
      if !ary
        return nil
      end
      hash = {}
      ary.each_with_index {|v, i|
        field = i < @header.length ? @header[i] : (i-@header.length+1).to_s
        hash[field] = v
      }
      hash
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

    def header_and_each(header_proc)
      header_proc.call(get_named_header) if header_proc
      while hash = get_hash
        yield hash
      end
      nil
    end

    def each(&b)
      header_and_each(nil, &b)
    end
  end
end
