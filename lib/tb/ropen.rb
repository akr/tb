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

def Tb.open_reader(filename, opts={})
  opts = opts.dup
  case filename
  when /\Acsv:/
    filename = $'
    table_reader_maker = lambda {|io| Tb::CSVReader.new(io) }
  when /\Atsv:/
    filename = $'
    table_reader_maker = lambda {|io| Tb::TSVReader.new(io) }
  when /\Altsv:/
    filename = $'
    pairs_reader_maker = lambda {|io| Tb::LTSVReader.new(io) }
  when /\Ap[pgbn]m:/
    filename = $'
    table_reader_maker = lambda {|io| Tb.pnm_stream_input(io) }
  when /\Ajson:/
    filename = $'
    whole_reader_maker = lambda {|io| Tb::JSONReader.new(io.read) }
  when /\.csv\z/
    table_reader_maker = lambda {|io| Tb::CSVReader.new(io) }
  when /\.tsv\z/
    table_reader_maker = lambda {|io| Tb::TSVReader.new(io) }
  when /\.ltsv\z/
    pairs_reader_maker = lambda {|io| Tb::LTSVReader.new(io) }
  when /\.p[pgbn]m\z/
    table_reader_maker = lambda {|io| Tb.pnm_stream_input(io) }
  when /\.json\z/
    whole_reader_maker = lambda {|io| Tb::JSONReader.new(io.read) }
  else
    table_reader_maker = lambda {|io| Tb::CSVReader.new(io) }
  end
  if !filename.respond_to?(:to_str) && !filename.respond_to?(:to_path)
    raise ArgumentError, "unexpected filename: #{filename.inspect}"
  end
  if whole_reader_maker
    if filename == '-'
      reader = whole_reader_maker.call($stdin)
    else
      reader = File.open(filename) {|io|
        whole_reader_maker.call(io)
      }
    end
  elsif pairs_reader_maker
    if filename == '-'
      reader = pairs_reader_maker.call($stdin)
    else
      reader = pairs_reader_maker.call(File.open(filename))
    end
  else
    # table_reader_maker should be available.
    reader = Tb::Reader.new(opts) {|body|
      if filename == '-'
        rawreader = table_reader_maker.call($stdin)
        body.call(rawreader)
      else
        File.open(filename) {|io|
          rawreader = table_reader_maker.call(io)
          body.call(rawreader)
        }
      end
    }
  end
  if block_given?
    yield reader
  else
    reader
  end
end

def Tb.open_reader2(filename, numeric=false)
  case filename
  when /\Acsv:/
    filename = $'
    reader_maker = lambda {|io| numeric ? Tb::NumericCSVReader.new(io) : Tb::HeaderCSVReader.new(io) }
  when /\Atsv:/
    filename = $'
    reader_maker = lambda {|io| numeric ? Tb::NumericTSVReader.new(io) : Tb::HeaderTSVReader.new(io) }
  when /\Altsv:/
    filename = $'
    reader_maker = lambda {|io| Tb::LTSVReader2.new(io) }
  when /\Ap[pgbn]m:/
    filename = $'
    reader_maker = lambda {|io| Tb::PNMReader2.new(io) }
  when /\Ajson:/
    filename = $'
    reader_maker = lambda {|io| Tb::JSONReader2.new(io) }
  when /\Ajsonl:/
    filename = $'
    reader_maker = lambda {|io| Tb::JSONLReader.new(io) }
  when /\.csv\z/
    reader_maker = lambda {|io| numeric ? Tb::NumericCSVReader.new(io) : Tb::HeaderCSVReader.new(io) }
  when /\.tsv\z/
    reader_maker = lambda {|io| numeric ? Tb::NumericTSVReader.new(io) : Tb::HeaderTSVReader.new(io) }
  when /\.ltsv\z/
    reader_maker = lambda {|io| Tb::LTSVReader2.new(io) }
  when /\.p[pgbn]m\z/
    reader_maker = lambda {|io| Tb::PNMReader2.new(io) }
  when /\.json\z/
    reader_maker = lambda {|io| Tb::JSONReader2.new(io) }
  when /\.jsonl\z/
    reader_maker = lambda {|io| Tb::JSONLReader.new(io) }
  else
    reader_maker = lambda {|io| numeric ? Tb::NumericCSVReader.new(io) : Tb::HeaderCSVReader.new(io) }
  end
  if !filename.respond_to?(:to_str) && !filename.respond_to?(:to_path)
    raise ArgumentError, "unexpected filename: #{filename.inspect}"
  end
  if filename == '-'
    reader = reader_maker.call($stdin)
  else
    reader = reader_maker.call(File.open(filename))
  end
  if block_given?
    yield reader
  else
    reader
  end
end

def Tb.open_writer(filename, numeric)
  if /\A([a-z0-9]{2,}):/ =~ filename
    fmt = $1
    filename = $'
  else
    fmt = nil
  end
  if !fmt
    case filename
    when /\.csv\z/ then fmt = 'csv'
    when /\.ltsv\z/ then fmt = 'ltsv'
    when /\.json\z/ then fmt = 'json'
    when /\.jsonl\z/ then fmt = 'jsonl'
    end
  end
  if fmt
    case fmt
    when 'csv'
      writer_maker = lambda {|out| numeric ? Tb::NumericCSVWriter.new(out) : Tb::HeaderCSVWriter.new(out) }
    when 'ltsv'
      writer_maker = lambda {|out| Tb::LTSVWriter.new(out) }
    when 'json'
      writer_maker = lambda {|out| Tb::JSONWriter.new(out) }
    when 'jsonl'
      writer_maker = lambda {|out| Tb::JSONLWriter.new(out) }
    else
      err("unexpected format: #{fmt.inspect}")
    end
  end
  writer_maker ||= lambda {|out| numeric ? Tb::NumericCSVWriter.new(out) : Tb::HeaderCSVWriter.new(out) }
  with_output(filename) {|out|
    writer = writer_maker.call(out)
    yield writer
    writer.finish
  }
end
