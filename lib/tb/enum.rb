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

  def with_header(&header_proc)
    Enumerator.new {|y|
      header_and_each(header_proc) {|pairs|
        y.yield pairs
      }
    }
  end

  def with_cumulative_header(&header_proc)
    Enumerator.new {|y|
      hset = {}
      internal_header_proc = lambda {|header0|
        if header0
          header0.each {|f|
            hset[f] = true
          }
        end
        header_proc.call(header0) if header_proc
      }
      header_and_each(internal_header_proc) {|pairs|
        pairs.each {|f, v|
          if !hset[f]
            hset[f] = true
          end
        }
        y.yield [pairs, hset.keys.freeze]
      }
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
        last_e.with_header {|last_e_header|
          if last_e_header && header
            header = last_e_header | header
          else
            header = nil
          end
          rec.call(y, header)
        }.each {|v|
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
      self.with_header {|header|
        if header
          y.set_header(Tb::FieldSet.normalize([field, *header]))
        end
      }.each {|row|
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

  def write_to_csv(io, with_header=true)
    stream = nil
    header = []
    fgen = fnew = nil
    self.with_cumulative_header {|header0|
      if !with_header
        stream = true
      elsif header0
        stream = true
        io.puts Tb.csv_encode_row(header0)
      else
        stream = false
        fgen, fnew = Tb::FileEnumerator.gen_new
      end
    }.each {|pairs, header1|
      pairs = Tb::Pairs.new(pairs) unless pairs.respond_to? :has_key?
      header = header1
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

  def extsort_by(opts={}, &cmpvalue_from)
    Tb::Enumerator.new {|ty|
      header = []
      er = Enumerator.new {|y|
        self.with_cumulative_header {|header0|
          header = header0 if header0
        }.each {|pairs, header1|
          header = header1
          y.yield pairs
        }
        ty.set_header header
      }
      er.extsort_by(opts, &cmpvalue_from).each {|pairs|
        ty.yield pairs
      }
    }
  end
end
