# lib/tb/ropen.rb - Tb.open_reader
#
# Copyright (C) 2011-2014 Tanaka Akira  <akr@fsij.org>
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

Tb::FormatHash = {
  'csv'    => [Tb::HeaderCSVReader,  Tb::HeaderCSVWriter],
  'ncsv'   => [Tb::NumericCSVReader, Tb::NumericCSVWriter],
  'tsv'    => [Tb::HeaderTSVReader,  Tb::HeaderTSVWriter],
  'ntsv'   => [Tb::NumericTSVReader, Tb::NumericTSVWriter],
  'ltsv'   => [Tb::LTSVReader,       Tb::LTSVWriter],
  'pnm'    => [Tb::PNMReader,        Tb::PNMWriter],
  'ppm'    => [Tb::PNMReader,        Tb::PNMWriter],
  'pgm'    => [Tb::PNMReader,        Tb::PNMWriter],
  'pbm'    => [Tb::PNMReader,        Tb::PNMWriter],
  'json'   => [Tb::JSONReader,       Tb::JSONWriter],
  'ndjson' => [Tb::NDJSONReader,     Tb::NDJSONWriter],
}

def Tb.undecorate_filename(filename, numeric)
  if filename.respond_to?(:to_str)
    filename = filename.to_str
  elsif filename.respond_to?(:to_path)
    filename = filename.to_path
  else
    raise ArgumentError, "unexpected filename: #{filename.inspect}"
  end
  if /\A([a-z0-9]{2,}):/ =~ filename
    fmt = $1
    filename = $'
    err("unexpected format: #{fmt.inspect}") if !Tb::FormatHash.has_key?(fmt)
  elsif /\.([a-z0-9]+{2,})\z/ =~ filename
    fmt = $1
    fmt = 'csv' if !Tb::FormatHash.has_key?(fmt)
  else
    fmt = 'csv'
  end
  if numeric
    case fmt
    when 'csv' then fmt = 'ncsv'
    when 'tsv' then fmt = 'ntsv'
    end
  end
  return filename, fmt
end

def Tb.open_reader(filename, numeric=false)
  filename, fmt = Tb.undecorate_filename(filename, numeric)
  factory = Tb::FormatHash.fetch(fmt)[0]
  io_opened = nil
  if filename == '-'
    reader = factory.new($stdin)
  else
    io_opened = File.open(filename)
    reader = factory.new(io_opened)
  end
  if block_given?
    begin
      yield reader
    ensure
      if io_opened && !io_opened.closed?
        io_opened.close
      end
    end
  else
    reader
  end
end
