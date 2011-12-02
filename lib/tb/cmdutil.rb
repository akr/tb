# Copyright (C) 2011 Tanaka Akira  <akr@fsij.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

class Tb::Cmd
  @subcommands = []
  @opt_N = nil
  @opt_debug = 0
  @opt_no_pager = nil
end

class << Tb::Cmd
  attr_reader :subcommands
  attr_accessor :opt_N 
  attr_accessor :opt_debug 
  attr_accessor :opt_no_pager
end

def err(msg)
  STDERR.puts msg
  exit 1
end

def comparison_value(v)
  case v
  when nil
    []
  when Numeric
    [0, v]
  when String
    case v
    when /\A\s*-?\d+\s*\z/
      [0, Integer(v)]
    when /\A\s*-?(\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?\s*\z/
      [0, Float(v)]
    else
      a = []
      v.scan(/(\d+)|\D+/) {
        if $1
          a << 0 << $1.to_i
        else
          a << 1 << $&
        end
      }
      a
    end
  else
    raise ArgumentError, "unexpected: #{v.inspect}"
  end
end

def conv_to_numeric(v)
  v = v.strip
  if /\A-?\d+\z/ =~ v
    v = v.to_i
  elsif /\A-?(\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?\z/ =~ v
    v = v.to_f
  else
    raise "numeric value expected: #{v.inspect}"
  end
  v
end

class CountAggregator
  def initialize() @result = 0 end
  def update(v) @result += 1 end
  def finish() @result end
end

class SumAggregator
  def initialize() @result = 0 end 
  def update(v) @result += conv_to_numeric(v) if !(v.nil? || v == '') end
  def finish() @result end
end

class AvgAggregator
  def initialize() @sum = 0; @count = 0 end 
  def update(v) @count += 1; @sum += conv_to_numeric(v) if !(v.nil? || v == '') end
  def finish() @sum / @count.to_f end
end

class MaxAggregator
  def initialize() @v = nil; @cmp = nil end 
  def update(v)
    cmp = comparison_value(v)
    if @cmp == nil
      @v, @cmp = v, cmp
    else
      @v, @cmp = v, cmp if (@cmp <=> cmp) < 0
    end
  end
  def finish() @v end
end

class MinAggregator
  def initialize() @v = @cmp = nil end 
  def update(v)
    cmp = comparison_value(v)
    if @cmp == nil
      @v, @cmp = v, cmp
    else
      @v, @cmp = v, cmp if (@cmp <=> cmp) > 0
    end
  end
  def finish() @v end
end

class ValuesAggregator
  def initialize() @result = [] end 
  def update(v) @result << v if v end
  def finish() @result.join(",") end
end

class UniqueValuesAggregator
  def initialize() @result = [] end 
  def update(v) @result << v if v end
  def finish() @result.uniq.join(",") end
end

class Selector
  def initialize(i, aggregator) @i = i; @agg = aggregator end
  def update(ary) @agg.update(ary[@i]) end
  def finish() @agg.finish end
end

def make_aggregator(spec, fs)
  case spec
  when 'count'
    CountAggregator.new
  when /\Asum\((.*)\)\z/
    field = $1
    i = fs.index(field)
    raise ArgumentError, "field not found: #{field.inspect}" if !i
    Selector.new(i, SumAggregator.new)
  when /\Aavg\((.*)\)\z/
    field = $1
    i = fs.index(field)
    raise ArgumentError, "field not found: #{field.inspect}" if !i
    Selector.new(i, AvgAggregator.new)
  when /\Amax\((.*)\)\z/
    field = $1
    i = fs.index(field)
    raise ArgumentError, "field not found: #{field.inspect}" if !i
    Selector.new(i, MaxAggregator.new)
  when /\Amin\((.*)\)\z/
    field = $1
    i = fs.index(field)
    raise ArgumentError, "field not found: #{field.inspect}" if !i
    Selector.new(i, MinAggregator.new)
  when /\Avalues\((.*)\)\z/
    field = $1
    i = fs.index(field)
    raise ArgumentError, "field not found: #{field.inspect}" if !i
    Selector.new(i, ValuesAggregator.new)
  when /\Auniquevalues\((.*)\)\z/
    field = $1
    i = fs.index(field)
    raise ArgumentError, "field not found: #{field.inspect}" if !i
    Selector.new(i, UniqueValuesAggregator.new)
  else
    raise ArgumentError, "unexpected aggregation spec: #{spec.inspect}"
  end
end

def aggregate(spec, table)
  update, finish = make_aggregator(spec, table.list_fields)
  table.each {|rec|
    update.call(rec.values_at(*fs))
  }
  finish.call
end

def decode_a1_addressing_col(str)
  (26**str.length-1)/25+str.tr("A-Z", "0-9A-P").to_i(26)
end

def split_field_list_argument(arg)
  split_csv_argument(arg).map {|f| f || '' }
end

def split_csv_argument(arg)
  Tb.csv_stream_input(arg) {|ary| return ary }
  return []
end

def each_table_file(argv)
  if argv.empty?
    yield load_table('-')
  else
    argv.each {|filename|
      tbl = load_table(filename)
      yield tbl
    }
  end
end

def load_table(filename)
  tablereader_open(filename) {|tblreader|
    arys = []
    tblreader.each {|ary|
      arys << ary
    }
    header = tblreader.header
    tbl = Tb.new(header)
    arys.each {|ary|
      ary << nil while ary.length < header.length
      tbl.insert_values header, ary
    }
    tbl
  }
end

def tablereader_open(filename, &b)
  Tb::Reader.open(filename, {:numeric=>Tb::Cmd.opt_N}, &b)
end

def with_table_stream_output
  with_output {|out|
    Tb.csv_stream_output(out) {|gen|
      def gen.output_header(header)
        self << header if !Tb::Cmd.opt_N
      end
      yield gen
    }
  }
end

def tbl_generate_csv(tbl, out)
  if Tb::Cmd.opt_N
    header = tbl.list_fields
    Tb.csv_stream_output(out) {|gen|
      tbl.each {|rec|
        gen << rec.values_at(*header)
      }
    }
  else
    tbl.generate_csv(out)
  end
end

def tbl_generate_tsv(tbl, out)
  if Tb::Cmd.opt_N
    header = tbl.list_fields
    Tb.tsv_stream_output(out) {|gen|
      tbl.each {|rec|
        gen << rec.values_at(*header)
      }
    }
  else
    tbl.generate_tsv(out)
  end
end

def with_output
  if STDOUT.tty? && !Tb::Cmd.opt_no_pager
    IO.popen(ENV['PAGER'] || 'more', 'w') {|pager|
      yield pager
    }
  else
    yield STDOUT
  end
end