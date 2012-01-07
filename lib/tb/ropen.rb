# lib/tb/ropen.rb - Tb::Reader.open
#
# Copyright (C) 2011 Tanaka Akira  <akr@fsij.org>
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

def Tb.open_reader(filename, opts={})
  opts = opts.dup
  case filename
  when /\Acsv:/
    filename = $'
    rawreader_maker = lambda {|io| Tb::CSVReader.new(io) }
  when /\Atsv:/
    filename = $'
    rawreader_maker = lambda {|io| Tb::TSVReader.new(io) }
  when /\Ap[pgbn]m:/
    filename = $'
    rawreader_maker = lambda {|io| Tb.pnm_stream_input(io) }
  when /\.csv\z/
    rawreader_maker = lambda {|io| Tb::CSVReader.new(io) }
  when /\.tsv\z/
    rawreader_maker = lambda {|io| Tb::TSVReader.new(io) }
  when /\.p[pgbn]m\z/
    rawreader_maker = lambda {|io| Tb.pnm_stream_input(io) }
  else
    rawreader_maker = lambda {|io| Tb::CSVReader.new(io) }
  end
  if !filename.respond_to?(:to_str) && !filename.respond_to?(:to_path)
    raise ArgumentError, "unexpected filename: #{filename.inspect}"
  end
  reader = Tb::Reader.new(opts) {|body|
    if filename == '-'
      rawreader = rawreader_maker.call($stdin)
      body.call(rawreader)
    else
      File.open(filename) {|io|
        rawreader = rawreader_maker.call(io)
        body.call(rawreader)
      }
    end
  }
  if block_given?
    yield reader
  else
    reader
  end
end
