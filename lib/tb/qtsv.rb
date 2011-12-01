# lib/tb/qtsv.rb - quoted TSV related fetures for table library
#
# Copyright (C) 2010 Tanaka Akira  <akr@fsij.org>
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

class Tb

  # quoted TSV is a variant of TSV (tab separated value)
  #
  # All non-empty values are quoted by double-quotes.

  def Tb.load_qtsv(filename, *header_fields, &block)
    Tb.parse_qtsv(File.read(filename), *header_fields, &block)
  end

  def Tb.qtsv_stream_input(qtsv)
    qtsv = qtsv.read unless String === qtsv
    qtsv = qtsv.dup
    cells = []
    verify = ''
    qtsv.scan(/\G("(.*?)"|)(\t|\n|\r\n|\z)/m) {
      verify << $&
      cell = $2
      sep = $3
      break if cell.nil? && sep.empty?
      cells << cell
      if sep != "\t"
        yield cells
        cells = []
      end
    }
    if verify != qtsv
      if qtsv.start_with?(verify)
        raise "unexpected scan ('verify' is a prefix of 'qtsv')"
      end
      if verify.length != qtsv.length
        raise "unexpected scan (length differ: orig:#{qtsv.length} verify:#{verify.length})" 
      end
      raise "unexpected scan" 
    end
    nil
  end

  def Tb.parse_qtsv(qtsv, *header_fields)
    aa = []
    qtsv_stream_input(qtsv) {|ary|
      aa << ary
    }
    aa = yield aa if block_given?
    if header_fields.empty?
      aa.shift while aa.first.all? {|elt| elt.nil? || elt == '' }
      header_fields = aa.shift
      h = Hash.new(0)
      header_fields.each_with_index {|f, i|
        if h.include? f
          raise ArgumentError, "ambiguous header field: #{f.inspect} (#{h[f]}th and #{i}th)"
        end
        h[f] = i
      }
    end
    t = Tb.new(header_fields)
    aa.each {|ary|
      h = {}
      header_fields.each_with_index {|f, i|
        h[f] = ary[i]
      }
      t.insert(h)
    }
    t
  end

end
