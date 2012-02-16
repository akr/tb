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

module Tb::Func
  def self.smart_cmp_value(v)
    case v
    when nil
      []
    when Numeric
      [0, v]
    when String
      if v.respond_to? :force_encoding
        v = v.dup.force_encoding("ASCII-8BIT")
      end
      case v
      when /\A\s*-?\d+\s*\z/
        [0, v.to_i(10)]
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

  def self.smart_numerize(v)
    return v if v.kind_of? Numeric
    v = v.strip
    if /\A-?\d+\z/ =~ v
      v = v.to_i
    elsif /\A-?(\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?\z/ =~ v
      v = v.to_f
    else
      raise ArgumentError, "number string expected: #{v.inspect}"
    end
    v
  end

  module Count; end
  def Count.start(value) 1 end
  def Count.call(v1, v2) v1 + v2 end
  def Count.aggregate(count) count end

  module Sum; end
  def Sum.start(value) Tb::Func.smart_numerize(value) end
  def Sum.call(v1, v2) v1 + v2 end
  def Sum.aggregate(sum) sum end

  module Min; end
  def Min.start(value) [value, Tb::Func.smart_cmp_value(value)]  end
  def Min.call(vc1, vc2) (vc1.last <=> vc2.last) <= 0 ? vc1 : vc2 end
  def Min.aggregate(vc) vc.first end

  module Max; end
  def Max.start(value) [value, Tb::Func.smart_cmp_value(value)]  end
  def Max.call(vc1, vc2) (vc1.last <=> vc2.last) >= 0 ? vc1 : vc2 end
  def Max.aggregate(vc) vc.first end

  module Avg; end
  def Avg.start(value) [Tb::Func.smart_numerize(value), 1] end
  def Avg.call(v1, v2) [v1[0] + v2[0], v1[1] + v2[1]] end
  def Avg.aggregate(sum_count) sum_count[0] / sum_count[1].to_f end

  module First; end
  def First.start(value) value end
  def First.call(v1, v2) v1 end
  def First.aggregate(value) value end

  module Last; end
  def Last.start(value) value end
  def Last.call(v1, v2) v2 end
  def Last.aggregate(value) value end

  module Values; end
  def Values.start(value) [value] end
  def Values.call(a1, a2) a1.concat a2 end
  def Values.aggregate(ary) ary.join(',') end

  module UniqueValues; end
  def UniqueValues.start(value) {value => true} end
  def UniqueValues.call(h1, h2) h1.update h2 end
  def UniqueValues.aggregate(hash) hash.keys.join(',') end

  class FirstN
    def initialize(n) @n = n end
    def start(value) [value] end
    def call(a1, a2) a1.length == @n ? a1 : (a1+a2).first(@n) end
    def aggregate(ary) ary end
  end

  class LastN
    def initialize(n) @n = n end
    def start(value) [value] end
    def call(a1, a2) a2.length == @n ? a2 : (a1+a2).last(@n) end
    def aggregate(ary) ary end
  end

  AggregationFunctions = {}
  Tb::Func.constants.each {|c|
    v = Tb::Func.const_get(c)
    if v.respond_to? :aggregate
      AggregationFunctions[c.to_s.downcase] = v
    end
  }

end
