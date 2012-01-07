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

class Tb::Enumerator < Enumerator
  include Tb::Enum

  def early_header
    if defined? @early_header
      return @early_header
    end
    nil
  end

  def set_early_header(header)
    if defined? @early_header
      raise ArgumentError, "@early_header is already set."
    end
    @early_header = header.dup.freeze
  end
end

module Tb::Enum
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
    er = nil
    empty = true
    rec = lambda {|y, header|
      if ers.empty?
        if header && !er.early_header
          er.set_early_header header
        end
      else
        last_e = ers.pop
        first = true
        last_e.each {|v|
          if first
            first = false
            if header && last_e.respond_to?(:early_header) && last_e.early_header
              header = last_e.early_header | header
            else
              header = nil
            end
            rec.call(y, header)
          end
          y.yield v
        }
        if first
          if header && last_e.respond_to?(:early_header) && last_e.early_header
            header = last_e.early_header | header
          else
            header = nil
          end
          rec.call(y, header)
        end
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
    er = Tb::Enumerator.new {|y|
      first = true
      self.each {|row|
        if first
          first = false
          if self.respond_to?(:early_header) && self.early_header && !er.early_header
            er.set_early_header(Tb::FieldSet.normalize([field, *self.early_header]))
          end
        end
        keys = row.map {|k, v| k }
        keys = Tb::FieldSet.normalize([field, *keys])
        vals = row.map {|k, v| v }
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

  # creates a Tb::FileEnumerator object.
  #
  def to_fileenumerator
    Tb::FileEnumerator.new_tempfile {|gen|
      self.each {|*objs|
        gen.call(*objs)
      }
    }
  end

  def write_to_csv_to_io(io, with_header=true)
    first = true
    early_header = nil
    header = []
    fgen = fnew = nil
    self.each {|pairs|
      if first
        first = false
        if !with_header
          early_header = []
        elsif early_header = self.early_header
          io.puts Tb.csv_encode_row(early_header)
          header = early_header.dup
        else
          fgen, fnew = Tb::FileEnumerator.gen_new
        end
      end
      header |= pairs.map {|f, v| f }
      if early_header
        fs = header.dup
        while !fs.empty? && !pairs.include?(fs.last)
          fs.pop
        end
        ary = fs.map {|f| pairs[f] }
        io.puts Tb.csv_encode_row(ary)
      else
        fgen.call Tb::Pairs.new(pairs)
      end
    }
    if first
      if self.early_header
        io.puts Tb.csv_encode_row(self.early_header)
      end
    elsif !early_header
      if with_header
        io.puts Tb.csv_encode_row(header)
      end
      fnew.call.each {|pairs|
        fs = header.dup
        while !fs.empty? && !pairs.include?(fs.last)
          fs.pop
        end
        ary = fs.map {|f| pairs[f] }
        io.puts Tb.csv_encode_row(ary)
      }
    end
  end

  # creates a CSV file named as _filename_.
  #
  # If _with_header_ is false,
  # the header row is not generated.
  #
  def write_to_csv(filename, with_header=true)
    keys_at_first = nil
    keys_at_last = nil
    k2i = {}
    part_filename = "#{filename}.part"
    open(part_filename, "w") {|f|
      Tb.csv_stream_output(f) {|gen|
        self.each_arypair {|ks, vs|
          if !keys_at_first
            keys_at_first = ks
            keys_at_last = ks
            if with_header
              gen << keys_at_first
            end
          end
          keys_at_last |= ks
          if k2i.length != keys_at_last.length
            i = keys_at_last.length - 1
            while 0 <= i && !k2i[keys_at_last[i]]
              k2i[keys_at_last[i]] = i
              i -= 1
            end
          end
          ary = []
          vs.each_with_index {|v, j|
            k = ks[j] # assumption: vs.length <= ks.length
            ary[k2i[k]] = v
          }
          gen << ary
        }
      }
    }
    if with_header && keys_at_first != keys_at_last
      part2_filename = "#{filename}.part2"
      open(part2_filename, "w") {|fw|
        Tb.csv_stream_output(fw) {|gen|
          open(part_filename) {|fr|
            reader = Tb::CSVReader.new(fr)
            reader.shift # consume keys_at_first
            gen << keys_at_last
            reader.each {|ary|
              gen << ary
            }
          }
        }
      }
      File.unlink part_filename
      part_filename = part2_filename
    end
    File.rename(part_filename, filename)
  end

end
