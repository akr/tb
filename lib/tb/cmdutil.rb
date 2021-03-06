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

class Tb::Cmd
  @subcommands = []

  @default_option = {
    :opt_help => 0,
    :opt_N => nil,
    :opt_debug => 0,
    :opt_no_pager => nil,
    :opt_output => nil,
  }

  def self.reset_option
    @default_option.each {|k, v|
      instance_variable_set("@#{k}", Marshal.load(Marshal.dump(v)))
    }
  end

  def self.init_option
    class << Tb::Cmd
      Tb::Cmd.default_option.each {|k, v|
        attr_accessor k
      }
    end
    reset_option
  end

  def self.define_common_option(op, short_opts, *long_opts)
    if short_opts.include? "h"
      op.def_option('-h', '--help', 'show help message (-hh for verbose help)') { Tb::Cmd.opt_help += 1 }
    end
    if short_opts.include? "N"
      op.def_option('-N', 'use numeric field name') { Tb::Cmd.opt_N = true }
    end
    if short_opts.include? "o"
      op.def_option('-o filename', 'output to specified filename') {|filename| Tb::Cmd.opt_output = filename }
    end
    if long_opts.include? "--no-pager"
      op.def_option('--no-pager', 'don\'t use pager') { Tb::Cmd.opt_no_pager = true }
    end
    opts = []
    opts << '-d' if short_opts.include?('d')
    opts << '--debug' if long_opts.include?('--debug')
    if !opts.empty?
      op.def_option(*(opts + ['show debug message'])) { Tb::Cmd.opt_debug += 1 }
    end
  end

  @verbose_help = {}
  def self.def_vhelp(subcommand, str)
    if @verbose_help[subcommand]
      raise ArgumentError, "verbose_help[#{subcommand.dump}] already defined."
    end
    @verbose_help[subcommand] = str
  end

  def self.subcommand_send(prefix, subcommand, *args, &block)
    self.send(prefix + "_" + subcommand.gsub(/-/, '_'), *args, &block)
  end
end

class << Tb::Cmd
  attr_reader :subcommands
  attr_reader :default_option
  attr_reader :verbose_help
end

def err(msg)
  raise SystemExit.new(1, msg)
end

def parse_aggregator_spec(spec)
  case spec
  when 'count'
    ['count', nil]
  when /\Asum\((.*)\)\z/
    ['sum', $1]
  when /\Aavg\((.*)\)\z/
    ['avg', $1]
  when /\Amax\((.*)\)\z/
    ['max', $1]
  when /\Amin\((.*)\)\z/
    ['min', $1]
  when /\Avalues\((.*)\)\z/
    ['values', $1]
  when /\Auniquevalues\((.*)\)\z/
    ['uniquevalues', $1]
  else
    raise ArgumentError, "unexpected aggregation spec: #{spec.inspect}"
  end
end

def parse_aggregator_spec2(spec)
  name, field = parse_aggregator_spec(spec)
  func = Tb::Func::AggregationFunctions[name]
  if !func
    raise ArgumentError, "unexpected aggregation spec: #{spec.inspect}"
  end
  [func, field]
end

def split_field_list_argument(arg)
  split_csv_argument(arg).map {|f| f || '' }
end

def split_csv_argument(arg)
  return CSV.new(arg).shift || []
end

def tablereader_open(filename, &b)
  Tb.open_reader(filename, Tb::Cmd.opt_N, &b)
end

def with_output(filename=Tb::Cmd.opt_output)
  if filename && filename != '-'
    tmp = filename + ".part"
    begin
      File.open(tmp, 'w') {|f|
        yield f
      }
      if File.exist?(filename) && FileUtils.compare_file(filename, tmp)
        File.unlink tmp
      else
        File.rename tmp, filename
      end
    ensure
      File.unlink tmp if File.exist? tmp
    end
  elsif $stdout.tty? && !Tb::Cmd.opt_no_pager
    Tb::Pager.open {|pager|
      yield pager
    }
  else
    yield $stdout
  end
end

def output_tbenum(te)
  filename = Tb::Cmd.opt_output || '-'
  numeric = Tb::Cmd.opt_N
  filename, fmt = Tb.undecorate_filename(filename, numeric)
  factory = Tb::FormatHash.fetch(fmt)[:writer]
  with_output(filename) {|out|
    writer = factory.new(out)
    te.write_with(writer)
  }
end
