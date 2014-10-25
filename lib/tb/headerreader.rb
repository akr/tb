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

module Tb
  class HeaderReader
    include Tb::EnumerableWithEach

    def initialize(get_array)
      @get_array = get_array
      @header_array_hook = nil
      @row_array_hook = nil
      @enable_warning = true
    end
    attr_accessor :header_array_hook
    attr_accessor :row_array_hook
    attr_accessor :enable_warning

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
      @header_array_hook.call(@header) if @header_array_hook
      h = Hash.new { [] }
      @header.each_with_index {|f, i|
        h[f] <<= i
      }
      if h.has_key? nil
        warn "Empty header field #{h[nil].map(&:succ).join(',')}" if @enable_warning
      end
      h.each {|f, is|
        if 1 < is.length
          warn "Ambiguous header field: field #{is.map(&:succ).join(',')} has same name #{f.inspect}" if @enable_warning
          is[1..-1].each {|i|
            @header[i] = nil
          }
        end
      }
    end
    private :read_header_once

    def get_named_header
      read_header_once
      @header.compact
    end

    def get_hash
      read_header_once
      ary = @get_array.call
      if !ary
        return nil
      end
      @row_array_hook.call(ary) if  @row_array_hook
      hash = {}
      if @header.length < ary.length
        warn "Header too short: header has #{@header.length} fields but a record has #{ary.length} fields : #{ary[@header.length..-1].map(&:inspect).join(',')}" if @enable_warning
        ary[@header.length..-1] = []
      end
      ary.each_with_index {|v, i|
        field = @header[i]
        if !field.nil?
          hash[field] = v
        end
      }
      hash
    end

    def header_and_each(header_proc)
      header_proc.call(get_named_header) if header_proc
      while hash = get_hash
        yield hash
      end
      nil
    end
  end
end
