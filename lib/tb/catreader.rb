# lib/tb/catreader.rb - Tb::CatReader class
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

class Tb::CatReader
  def self.open(filenames, numeric=false)
    readers = []
    filenames.each {|f|
      readers << Tb::Reader.open(f, numeric ? {:numeric=>true} : {})
    }
    r = Tb::CatReader.new(readers, readers, numeric)
    if block_given?
      begin
        yield r
      ensure
        r.close
      end
    else
      r
    end
  end

  def initialize(readers, also_close, numeric)
    @readers = readers.dup
    @also_close = also_close
    @numeric = numeric
    @fieldset = nil
  end

  def header
    return @fieldset.header if @fieldset
    if @numeric
      @fieldset = Tb::FieldSet.new
    else
      h = {}
      @readers.each {|r|
        r.header.each {|f|
          if !h[f]
            h[f] = h.size
          end
        }
      }
      @fieldset = Tb::FieldSet.new(*h.keys.sort_by {|f| h[f] })
    end
    return @fieldset.header
  end

  def index_from_field_ex(f)
    self.header
    @fieldset.index_from_field_ex(f)
  end

  def index_from_field(f)
    self.header
    @fieldset.index_from_field(f)
  end

  def field_from_index_ex(i)
    self.header
    @fieldset.field_from_index_ex(i)
  end

  def field_from_index(i)
    self.header
    @fieldset.field_from_index(i)
  end

  def shift
    self.header
    while !@readers.empty?
      r = @readers.first
      ary = r.shift
      if ary
        h = r.header
        ary2 = []
        ary.each_with_index {|v,i|
          f = h[i]
          i2 = @fieldset.index_from_field_ex(f)
          ary2[i2] = v
        }
        return ary2
      else
        @readers.shift
      end
    end
    nil
  end

  def each
    raise NotImplementedError
  end

  def each_values
    while ary = self.shift
      yield ary
    end
    nil
  end

  def read_all
    result = []
    while ary = self.shift
      result << ary
    end
    result
  end

  def close
    if @also_close
      @also_close.each {|x| x.close }
    end
  end
end
