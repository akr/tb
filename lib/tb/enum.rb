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

module Tb::Enum
  include Enumerable
end

class Tb::Yielder
  def initialize(header_proc, each_proc)
    @header_proc_called = false
    @header_proc = header_proc
    @each_proc = each_proc
  end
  attr_reader :header_proc_called

  def set_header(header)
    raise ArgumentError, "set_header called twice" if @header_proc_called
    @header_proc_called = true
    @header_proc.call(header) if @header_proc
  end

  def yield(*args)
    if !@header_proc_called
      set_header(nil)
    end
    @each_proc.call(*args)
  end
  alias << yield
end

class Tb::Enumerator
  include Tb::Enum

  def initialize(&enumerator_proc)
    @enumerator_proc = enumerator_proc
  end

  def each(&each_proc)
    yielder = Tb::Yielder.new(nil, each_proc)
    @enumerator_proc.call(yielder)
    nil
  end

  def header_and_each(header_proc, &each_proc)
    yielder = Tb::Yielder.new(header_proc, each_proc)
    @enumerator_proc.call(yielder)
    if !yielder.header_proc_called
      header_proc.call(nil)
    end
    nil
  end
end

module Tb::Enum
  def header_and_each(header_proc, &block)
    header_proc.call(nil) if header_proc
    self.each(&block)
  end

  def each_arypair
    self.each {|pairs|
      ks = []
      vs = []
      pairs.each {|k, v|
        ks << k
        vs << v
      }
      yield [ks, vs]
    }
  end

  def cat(*ers, &b)
    ers = [self, *ers]
    rec = lambda {|y, header|
      if ers.empty?
        if header
          y.set_header header
        end
      else
        last_e = ers.pop
        header_proc = lambda {|last_e_header|
          if last_e_header && header
            header = last_e_header | header
          else
            header = nil
          end
          rec.call(y, header)
        }
        last_e.header_and_each(header_proc) {|v|
          y.yield v
        }
      end
    }
    er = Tb::Enumerator.new {|y|
      rec.call(y, [])
    }
    if block_given?
      er.each(&b)
    else
      er
    end
  end

  # creates a new Tb::Enumerator object which have
  # new field named by _field_ with the value returned by the block.
  #
  #   t1 = Tb.new %w[a b], [1, 2], [3, 4]
  #   p t1.newfield("x") {|row| row["a"] + row["b"] + 100 }.to_a
  #   #=> [#<Tb::Pairs: "x"=>103, "a"=>1, "b"=>2>,
  #   #    #<Tb::Pairs: "x"=>107, "a"=>3, "b"=>4>]
  #
  def newfield(field)
    Tb::Enumerator.new {|y|
      header_proc = lambda {|header|
        if header
          y.set_header(Tb::FieldSet.normalize([field, *header]))
        end
      }
      self.header_and_each(header_proc) {|row|
        keys = row.keys
        keys = Tb::FieldSet.normalize([field, *keys])
        vals = row.values
        vals = [yield(row), *vals]
        y << Tb::Pairs.new(keys.zip(vals))
      }
    }
  end

  def to_tb
    tb = Tb.new
    self.each {|pairs|
      pairs.each {|k, v|
        unless tb.has_field? k
          tb.define_field(k)
        end
      }
      tb.insert pairs
    }
    tb
  end

  def write_to_csv_to_io(io, with_header=true)
    stream = nil
    header = []
    fgen = fnew = nil
    header_proc = lambda {|header0|
      if !with_header
        stream = true
      elsif header0
        stream = true
        io.puts Tb.csv_encode_row(header0)
        header = header0.dup
      else
        stream = false
        fgen, fnew = Tb::FileEnumerator.gen_new
      end
    }
    self.header_and_each(header_proc) {|pairs|
      pairs = Tb::Pairs.new(pairs) unless pairs.respond_to? :has_key?
      header |= pairs.keys
      if stream
        fs = header.dup
        while !fs.empty? && !pairs.has_key?(fs.last)
          fs.pop
        end
        ary = fs.map {|f| pairs[f] }
        io.puts Tb.csv_encode_row(ary)
      else
        fgen.call Tb::Pairs.new(pairs)
      end
    }
    if !stream
      if with_header
        io.puts Tb.csv_encode_row(header)
      end
      fnew.call.each {|pairs|
        fs = header.dup
        while !fs.empty? && !pairs.has_key?(fs.last)
          fs.pop
        end
        ary = fs.map {|f| pairs[f] }
        io.puts Tb.csv_encode_row(ary)
      }
    end
  end

end
