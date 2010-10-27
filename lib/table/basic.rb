# lib/table/basic.rb - basic fetures for table library
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

require 'pp'

class Table
  def initialize
    @free_rowids = []
    @tbl = {"_rowid"=>[]}
  end

  def pretty_print(q)
    q.object_group(self) {
      each_row {|row|
        q.breakable
        q.pp row
      }
    }
  end
  alias inspect pretty_print_inspect

  def check_rowid(rowid)
    raise IndexError, "unexpected rowid: #{rowid}" if !rowid.kind_of?(Integer) || rowid < 0
  end

  def all_rowids
    @tbl["_rowid"].compact
  end

  def allocate_rowid
    if @free_rowids.empty?
      rowid = @tbl["_rowid"].length
      @tbl["_rowid"] << rowid
    else
      rowid = @free_rowids.pop
    end
    rowid
  end

  def store_cell(rowid, field, value)
    check_rowid(rowid)
    field = field.to_s
    ary = (@tbl[field] ||= [])
    ary[rowid] = value
  end

  def lookup_cell(rowid, field)
    check_rowid(rowid)
    field = field.to_s
    ary = @tbl[field]
    ary ? ary[rowid] : nil
  end

  def delete_cell(rowid, field)
    check_rowid(rowid)
    field = field.to_s
    ary = @tbl[field]
    ary[rowid] = nil
  end

  def delete_rowid(rowid)
    check_rowid(rowid)
    row = {}
    @tbl.each {|f, ary|
      v = ary[rowid]
      ary[rowid] = nil
      row[f] = v if !v.nil?
    }
    @free_rowids.push rowid
    row
  end

  def insert(row)
    rowid = allocate_rowid
    update_rowid(rowid, row)
    rowid
  end

  def concat(*tables)
    tables.each {|t|
      t.each_row {|row|
        row.delete "_rowid"
        self.insert row
      }
    }
    self
  end

  def update_rowid(rowid, row)
    check_rowid(rowid)
    row.each {|f, v|
      f = f.to_s
      store_cell(rowid, f, v)
    }
  end

  def lookup_rowid(rowid, *fields)
    check_rowid(rowid)
    fields.map {|f|
      f = f.to_s
      lookup_cell(rowid, f)
    }
  end

  def get_by_rowid(rowid)
    result = {}
    @tbl.each {|f, ary|
      v = ary[rowid]
      next if v.nil?
      result[f] = v
    }
    result
  end

  def each_rowid
    @tbl["_rowid"].each {|rowid|
      next if rowid.nil?
      yield rowid
    }
  end

  def each_row(*fields)
    if fields.empty?
      each_rowid {|rowid|
        next if rowid.nil?
        yield get_by_rowid(rowid)
      }
    else
      each_rowid {|rowid|
        next if rowid.nil?
        values = lookup_rowid(rowid, *fields)
        h = {}
        fields.each_with_index {|f, i|
          h[f] = values[i]
        }
        yield h
      }
    end
  end

  def each_row_array(*fields)
    each_rowid {|rowid|
      vs = lookup_rowid(rowid, *fields)
      yield vs
    }
  end

  def make_hash(*args)
    opts = args.last.kind_of?(Hash) ? args.pop : {}
    seed_value = opts[:seed]
    value_field = args.pop
    key_fields = args
    value_array_p = value_field.kind_of?(Array)
    all_fields = key_fields + (value_array_p ? value_field : [value_field])
    result = {}
    each_row_array(*all_fields) {|all_values|
      if value_array_p
        value = all_values.last(value_field.length)
        vs = all_values[0, key_fields.length]
      else
        value = all_values.last
        vs = all_values[0, key_fields.length]
      end
      lastv = vs.pop
      h = result
      vs.each {|v|
        h[v] = {} if !h.include?(v)
        h = h[v]
      }
      if block_given?
        if !h.include?(lastv)
          h[lastv] = yield(seed_value, value)
        else
          h[lastv] = yield(h[lastv], value)
        end
      else
        if !h.include?(lastv)
          h[lastv] = value 
        else
          raise ArgumentError, "ambiguous key: #{(vs+[lastv]).map {|v| v.inspect }.join(',')}"
        end
      end
    }
    result
  end

  def make_hash_array(*args)
    make_hash(*args) {|seed, value| !seed ? [value] : (seed << value) }
  end

  def make_hash_count(*args)
    make_hash(*args) {|seed, value| !seed ? 1 : seed+1 }
  end
end
