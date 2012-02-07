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
  #   #=> [{"x"=>103, "a"=>1, "b"=>2},
  #   #    {"x"=>107, "a"=>3, "b"=>4}]
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
        y << Hash[keys.zip(vals)]
      }
    }
  end

  # :call-seq:
  #   table1.natjoin2(table2, missing_value=nil, retain_left=false, retain_right=false)
  def natjoin2(tbl2, missing_value=nil, retain_left=false, retain_right=false)
    Tb::Enumerator.new {|y|
      tbl1 = self
      header1 = header2 = nil
      sorted_tbl2 = nil
      common_header = nil
      total_header = nil
      sorted_tbl1 = tbl1.with_header {|h1|
        header1 = h1
        sorted_tbl2 = tbl2.with_header {|h2|
          header2 = h2
          common_header = header1 & header2
          total_header = header1 | header2
          y.set_header total_header
        }.lazy_map {|pairs|
          [common_header.map {|f| pairs[f] }, pairs]
        }.extsort_by {|cv, pairs| cv }.to_fileenumerator
      }.lazy_map {|pairs|
        [common_header.map {|f| pairs[f] }, pairs]
      }.extsort_by {|cv, pairs| cv }.to_fileenumerator
      sorted_tbl1.open_reader {|t1|
        sorted_tbl2.open_reader {|t2|
          missing_hash = {}
          total_header.each {|f|
            missing_hash[f] = missing_value
          }
          Tb::Enumerator.merge_sorted(t1, t2) {|cv, t1_or_nil, t2_or_nil|
            if !t2_or_nil
              t1.subeach_by {|_cv1, _| _cv1 }.each {|_, _pairs1|
                if retain_left
                  y.yield missing_hash.merge(_pairs1.to_hash)
                end
              }
            elsif !t1_or_nil
              t2.subeach_by {|_cv2, _| _cv2 }.each {|_, _pairs2|
                if retain_right
                  y.yield missing_hash.merge(_pairs2.to_hash)
                end
              }
            else # t1_or_nil && t1_or_nil
              t2_pos = t2.pos
              t1.subeach_by {|_cv1, _| _cv1 }.each {|_, _pairs1|
                t2.pos = t2_pos
                t2.subeach_by {|_cv2, _| _cv2 }.each {|_, _pairs2|
                  y.yield(_pairs2.to_hash.merge(_pairs1.to_hash))
                }
              }
            end
          }
        }
      }
    }
  end

  # :call-seq:
  #   table1.natjoin2_outer(table2, missing=nil, retain_left=true, retain_right=true)
  def natjoin2_outer(tbl2, missing_value=nil, retain_left=true, retain_right=true)
    natjoin2(tbl2, missing_value, retain_left, retain_right)
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
      pairs = Hash[pairs] unless pairs.respond_to? :has_key?
      header = header1
      if stream
        fs = header.dup
        while !fs.empty? && !pairs.has_key?(fs.last)
          fs.pop
        end
        ary = fs.map {|f| pairs[f] }
        io.puts Tb.csv_encode_row(ary)
      else
        fgen.call Hash[pairs]
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
