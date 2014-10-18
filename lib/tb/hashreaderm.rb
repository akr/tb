# lib/tb/hashreaderm.rb - reader mixin for table without header
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
  # HashReaderMixin should be mixed to a class which get_hash_internal is implemented.
  module HashReaderMixin
    def header_known?
      false
    end

    def get_header
      if defined? @hashreader_header_complete
        return @hashreader_header_complete
      end
      @hashreader_buffer = []
      while hash = get_hash_internal
        update_header hash
        @hashreader_buffer << hash
      end
      update_header nil
    end

    def get_hash
      if defined? @hashreader_buffer
        return @hashreader_buffer.shift
      end
      hash = get_hash_internal
      update_header hash
      hash
    end

    def update_header(hash)
      unless defined? @hashreader_header_partial
        @hashreader_header_partial = []
      end
      if hash
        @hashreader_header_partial.concat(hash.keys - @hashreader_header_partial)
      else
        @hashreader_header_complete = @hashreader_header_partial
      end
    end

    def each
      while hash = get_hash
        yield hash
      end
      nil
    end
  end
end
