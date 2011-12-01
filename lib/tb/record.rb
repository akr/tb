# lib/tb/record.rb - record class for table library
#
# Copyright (C) 2010-2011 Tanaka Akira  <akr@fsij.org>
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

class Tb::Record
  include Enumerable

  def initialize(table, recordid)
    @table = table
    @recordid = recordid
  end
  attr_reader :table

  def record_id
    @recordid
  end

  def pretty_print(q) # :nodoc:
    q.object_group(self) {
      fs = @table.list_fields.reject {|f| self[f].nil? }
      unless fs.empty?
        q.text ':'
        q.breakable
      end
      q.seplist(fs, nil, :each) {|f|
        v = self[f]
        q.group {
          q.pp f
          q.text '=>'
          q.group(1) {
            q.breakable ''
            q.pp v
          }
        }
      }
    }
  end
  alias inspect pretty_print_inspect # :nodoc:

  def has_field?(field)
    @table.has_field?(field)
  end

  def [](field)
    @table.get_cell(@recordid, field)
  end

  def []=(field, value)
    @table.set_cell(@recordid, field, value)
  end

  def to_h
    h = {}
    @table.each_field {|f|
      v = @table.get_cell(@recordid, f)
      h[f] = v if !v.nil?
    }
    h
  end

  def to_h_with_reserved
    h = {}
    @table.each_field_with_reserved {|f|
      v = @table.get_cell(@recordid, f)
      h[f] = v if !v.nil?
    }
    h
  end

  def to_a
    a = {}
    @table.each_field {|f|
      v = @table.get_cell(@recordid, f)
      a << [f, v] if !v.nil?
    }
    a
  end

  def to_a_with_reserved
    a = {}
    @table.each_field_with_reserved {|f|
      v = @table.get_cell(@recordid, f)
      a << [f, v] if !v.nil?
    }
    a
  end

  def each
    @table.each_field {|f|
      v = @table.get_cell(@recordid, f)
      yield [f, v] if !v.nil?
    }
    nil
  end

  def each_with_reserved
    @table.each_field_reserved {|f|
      v = @table.get_cell(@recordid, f)
      yield [f, v] if !v.nil?
    }
    nil
  end

  def values_at(*fields)
    fields.map {|f| self[f] }
  end
end
