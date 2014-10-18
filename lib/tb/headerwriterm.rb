# lib/tb/headerwriterm.rb - writer mixin for table with header
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

require 'tempfile'

class Tb
  module HeaderWriterMixin
    def header_required?
      true
    end

    def header_generator=(gen)
      @header_generator = gen
    end

    def generate_header_if_possible
      return if defined? @header_use_buffer
      if defined? @header_generator
        @header_use_buffer = false
        @header = @header_generator.call
        put_array @header
      else
        @header_use_buffer = true
        @header = []
        @header_buffer = Tempfile.new('tb')
      end
    end

    def put_hash(hash)
      generate_header_if_possible
      if @header_use_buffer
        put_hash_buffer(hash)
      else
        put_hash_immediate(hash)
      end
      nil
    end

    def put_hash_buffer(hash)
      Marshal.dump(hash, @header_buffer)
      (hash.keys - @header).each {|f|
        @header << f
      }
    end
    private :put_hash_buffer

    def finish
      generate_header_if_possible
      if @header_use_buffer == nil
        generate_header_if_possible
      end
      if @header_use_buffer
        @header_buffer.rewind
        put_array(@header)
        begin
          while true
            hash = Marshal.load(@header_buffer)
            put_hash_immediate(hash)
          end
        rescue EOFError
        end
      end
    end

    def put_hash_immediate(hash)
      ary = []
      @header.each {|f|
        ary << hash[f]
      }
      (hash.keys - @header).each {|f|
        warn "unexpected field: #{f.inspect}"
        @header << f
        ary << hash[f]
      }
      put_array ary
    end
    private :put_hash_immediate
  end
end
