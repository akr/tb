# Copyright (C) 2012 Tanaka Akira  <akr@fsij.org>
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

require 'json'

class Tb
  class JSONReader
    include Tb::Enumerable

    def initialize(string)
      @ary = JSON.parse(string)
    end

    def header_and_each(header_proc)
      header_proc.call(nil) if header_proc
      @ary.each {|obj|
        yield obj
      }
    end

    def each(&block)
      header_and_each(nil, &block)
    end
  end

  class JSONReader2 < Tb::HashReader
    def initialize(io)
      ary = JSON.parse(io.read)
      super lambda { ary.shift }
    end
  end

  class JSONWriter < Tb::HashWriter
    def initialize(io)
      io << "[\n"
      sep = ""
      super lambda {|hash|
        io << sep << JSON.pretty_generate(hash)
        sep = ",\n"
      },
      lambda {
        io << "\n]\n"
      }
    end
  end
end
