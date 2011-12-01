# lib/tb/fieldset.rb - Tb::FieldSet class
#
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

class Tb::FieldSet
  def initialize(*fs)
    @header = []
    add_fields(*fs) if !fs.empty?
  end
  attr_reader :header

  def index_from_field(f)
    i = self.header.index(f)
    if i.nil?
      raise ArgumentError, "unexpected field name: #{f.inspect}"
    end
    i
  end

  def field_from_index_ex(i)
    if self.length <= i
      fs2 = extend_length(i+1)
      fs2.last
    else
      field_from_index(i)
    end
  end

  def field_from_index(i)
    raise ArgumentError, "negative index: #{i}" if i < 0
    f = self.header[i]
    if f.nil?
      raise ArgumentError, "index too big: #{i}"
    end
    f
  end

  def length
    @header.length
  end

  def extend_length(len)
    fs = [""] * (len - self.length)
    add_fields(*fs)
  end

  def add_fields(*fs)
    h = {}
    max = {}
    @header.each {|f|
      h[f] = true
      if /\((\d+)\)\z/ =~ f
        prefix = $`
        n = $1.to_i
        max[prefix] = n if !max[prefix] || max[prefix] < n
      end
    }
    fs2 = []
    fs.each {|f|
      f ||= ''
      if !h[f]
        f2 = f
      else
        max[f] = 1 if !max[f]
        max[f] += 1
        f2 = "#{f}(#{max[f]})"
      end
      fs2 << f2
      h[f2] = true
    }
    @header.concat fs2
    fs2
  end
end
