# lib/table/csv.rb - CSV related fetures for table library
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

class Table

  def Table.load_csv(filename, *header_fields, &block)
    Table.parse_csv(File.read(filename), *header_fields, &block)
  end

  def Table.parse_csv(csv, *header_fields)
    require 'csv'
    aa = []
    if defined? CSV::Reader
      # Ruby 1.8
      CSV::Reader.parse(csv) {|ary|
        ary = ary.map {|cell| cell.nil? ? nil : cell.to_s }
        aa << ary
      }
    else
      # Ruby 1.9
      CSV.parse(csv) {|ary|
        ary = ary.map {|val| val.nil? ? nil : val.to_s }
        aa << ary
      }
    end
    aa = yield aa if block_given?
    if header_fields.empty?
      aa.shift while aa.first.all? {|elt| elt.nil? || elt == '' }
      header_fields = aa.shift
      header_fields.pop while !header_fields.empty? && header_fields.last.nil?
      h = Hash.new(0)
      header_fields.each {|f| h[f] += 1 }
      h.each {|f, n|
        if 1 < n
          raise ArgumentError, "ambiguous header: #{f.inspect}"
        end
      }
    end
    header_fields = header_fields.map {|f| f.nil? ? "" : f }
    t = Table.new(header_fields)
    aa.each {|ary|
      h = {}
      header_fields.each_with_index {|f, i|
        h[f] = ary[i]
      }
      t.insert(h)
    }
    t
  end

  # :call-seq:
  #   generate_csv(out='', fields=nil) {|recordids| modified_recordids }
  #   generate_csv(out='', fields=nil)
  #
  def generate_csv(out='', fields=nil, &block)
    if fields.nil?
      fields = list_fields.reject {|f| /\A_/ =~ f }
    end
    require 'csv'
    recordids = list_recordids
    if block_given?
      recordids = yield(recordids)
    end
    if defined? CSV::Writer
      # Ruby 1.8
      CSV::Writer.generate(out) {|csvgen|
        csvgen << fields
        recordids.each {|recordid|
          csvgen << get_values(recordid, *fields)
        }
      }
    else
      # Ruby 1.9
      out << fields.to_csv
      recordids.each {|recordid|
        values = get_values(recordid, *fields)
        str = values.to_csv
        out << str
      }
    end
    out
  end
end
