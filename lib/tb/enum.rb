# Copyright (C) 2012 Tanaka Akira  <akr@fsij.org>
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

module Tb::Enum
  include Enumerable

  # creates a Tb::FileEnumerator object.
  #
  def fileenumerator
    Tb::FileEnumerator.new_tempfile {|gen|
      self.each {|*objs|
        gen.call(*objs)
      }
    }
  end

  # creates a CSV file named as _filename_.
  #
  # If _with_header_ is false,
  # the header row is not generated.
  #
  # +self.each+ should yield a pair of arrays: [fieldname_ary, value_ary].
  #
  def write_to_csv(filename, with_header=true)
    keys_at_first = nil
    keys_at_last = nil
    k2i = {}
    part_filename = "#{filename}.part"
    open(part_filename, "w") {|f|
      Tb.csv_stream_output(f) {|gen|
        self.each {|ks, vs|
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