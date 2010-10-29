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
  def initialize(*args)
    @free_itemids = []
    @tbl = {"_itemid"=>[]}
    if !args.empty?
      insert_values(*args)
    end
  end

  def pretty_print(q)
    q.object_group(self) {
      each_item {|item|
        q.breakable
        q.pp item
      }
    }
  end
  alias inspect pretty_print_inspect

  def check_itemid(itemid)
    raise IndexError, "unexpected itemid: #{itemid.inspect}" if !itemid.kind_of?(Integer) || itemid < 0
  end

  # call-seq:
  #   table.list_fields -> [field1, field2, ...]
  def list_fields
    @tbl.keys
  end

  # call-seq:
  #   table.list_itemids -> [itemid1, itemid2, ...]
  def list_itemids
    @tbl["_itemid"].compact
  end

  def size
    @tbl["_itemid"].length - @free_itemids.length
  end

  # call-seq:
  #   table.allocate_itemid -> fresh_itemid
  def allocate_itemid
    if @free_itemids.empty?
      itemid = @tbl["_itemid"].length
      @tbl["_itemid"] << itemid
    else
      itemid = @free_itemids.pop
      @tbl["_itemid"][itemid] = itemid
    end
    itemid
  end

  # call-seq:
  #   table.set_cell(itemid, field, value) -> value
  def set_cell(itemid, field, value)
    check_itemid(itemid)
    field = field.to_s
    raise ArgumentError, "can not set _itemid" if field == "_itemid"
    ary = (@tbl[field] ||= [])
    ary[itemid] = value
  end

  # call-seq:
  #   table.get_cell(itemid, field) -> value
  def get_cell(itemid, field)
    check_itemid(itemid)
    field = field.to_s
    ary = @tbl[field]
    ary ? ary[itemid] : nil
  end

  # same as set_cell(itemid, field, nil)
  def delete_cell(itemid, field)
    check_itemid(itemid)
    field = field.to_s
    raise ArgumentError, "can not delete _itemid" if field == "_itemid"
    ary = @tbl[field]
    ary[itemid] = nil
  end

  # call-seq:
  #   table.delete_item(itemid) -> {field1=>value1, ...}
  def delete_item(itemid)
    check_itemid(itemid)
    item = {}
    @tbl.each {|f, ary|
      v = ary[itemid]
      ary[itemid] = nil
      item[f] = v if !v.nil?
    }
    @free_itemids.push itemid
    item
  end

  # call-seq:
  #   table.insert({field1=>value1, ...})
  #
  def insert(item)
    itemid = allocate_itemid
    update_item(itemid, item)
    itemid
  end

  # call-seq
  #   table.insert_values(fields, values1, values2, ...)
  #
  # Example:
  #   # same as:
  #   #   table.insert({"a"=>1, "b"=>2})
  #   #   table.insert({"a"=>3, "b"=>4})
  #   table.insert_values(%w[a b], [1, 2], [3, 4])
  def insert_values(fields, *values_list)
    values_list.each {|values|
      if values.length != fields.length
        raise ArgumentError, "#{fields.length} fields expected but #{values.length} values given"
      end
      h = {}
      fields.each_with_index {|f, i|
        v = values[i]
        h[f] = v
      }
      insert h
    }
  end

  # call-seq:
  #   table1.concat(table2, table3, ...) -> table1
  def concat(*tables)
    tables.each {|t|
      t.each_item {|item|
        item.delete "_itemid"
        self.insert item
      }
    }
    self
  end

  # call-seq:
  #   table.update_item(itemid, {field1=>value1, ...}) -> nil
  def update_item(itemid, item)
    check_itemid(itemid)
    item.each {|f, v|
      f = f.to_s
      set_cell(itemid, f, v)
    }
    nil
  end

  # call-seq:
  #   table.get_values(itemid, field1, field2, ...) -> [value1, value2, ...]
  def get_values(itemid, *fields)
    check_itemid(itemid)
    fields.map {|f|
      f = f.to_s
      get_cell(itemid, f)
    }
  end

  # call-seq:
  #   table.get_item(itemid) -> {field1=>value1, ...}
  def get_item(itemid)
    result = {}
    @tbl.each {|f, ary|
      v = ary[itemid]
      next if v.nil?
      result[f] = v
    }
    result
  end

  # call-seq:
  #   table.each_itemid {|itemid| ... }
  def each_itemid
    @tbl["_itemid"].each {|itemid|
      next if itemid.nil?
      yield itemid
    }
  end

  # call-seq:
  #   table.to_a -> [{field1=>value1, ...}, ...]
  def to_a
    ary = []
    each_itemid {|itemid|
      ary << get_item(itemid)
    }
    ary
  end

  # call-seq:
  #   table.each {|item| ... }
  #   table.each_item {|item| ... }
  def each_item
    each_itemid {|itemid|
      next if itemid.nil?
      yield get_item(itemid)
    }
  end
  alias each each_item

  # call-seq:
  #   table.each_item_values(field1, ...) {|value1, ...| ... }
  def each_item_values(*fields)
    each_itemid {|itemid|
      vs = get_values(itemid, *fields)
      yield vs
    }
  end

  # call-seq:
  #   table.make_hash(key_field1, key_field2, ..., value_field, :seed=>initial_seed) {|seed, value| ... } -> hash
  #
  # make_hash takes following arguments:
  # - one or more key fields
  # - value field which can be a single field name or an array of field names
  # -- a single field
  # -- an array of field names
  # -- true
  # - optional option hash which may contains:
  # -- :seed option
  #
  # make_hash takes optional block.
  #
  def make_hash(*args)
    opts = args.last.kind_of?(Hash) ? args.pop : {}
    seed_value = opts[:seed]
    value_field = args.pop
    key_fields = args
    case value_field
    when Array
      value_field_list = value_field.map {|f| f.to_s }
      gen_value = lambda {|all_values| all_values.last(value_field.length) }
    when true
      value_field_list = []
      gen_value = lambda {|all_values| true }
    else
      value_field_list = [value_field.to_s]
      gen_value = lambda {|all_values| all_values.last }
    end
    all_fields = key_fields + value_field_list
    result = {}
    each_item_values(*all_fields) {|all_values|
      value = gen_value.call(all_values)
      vs = all_values[0, key_fields.length]
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

  # call-seq:
  #   table.make_hash_array(key_field1, key_field2, ..., value_field)
  def make_hash_array(*args)
    make_hash(*args) {|seed, value| !seed ? [value] : (seed << value) }
  end

  # call-seq:
  #   table.make_hash_count(key_field1, key_field2, ...)
  def make_hash_count(*args)
    make_hash(*(args + [true])) {|seed, value| !seed ? 1 : seed+1 }
  end

  # call-seq:
  #   table.reject {|item| ... }
  def reject
    t = Table.new
    each_item {|item|
      if !yield(item)
        item.delete "_itemid"
        t.insert item
      end
    }
    t
  end

  # call-seq:
  #   table1.natjoin2(table2, rename_field1={}, rename_field2={}) {|item| ... }
  def natjoin2(table2, rename_field1={}, rename_field2={})
    table1 = self
    fields1 = table1.list_fields.map {|f| rename_field1.fetch(f, f) }
    fields2 = table2.list_fields.map {|f| rename_field2.fetch(f, f) }
    fields1.delete("_itemid")
    fields2.delete("_itemid")
    common_fields = fields1 & fields2
    hash = table2.make_hash_array(*(common_fields + ["_itemid"]))
    result = Table.new
    table1.each_item {|item1|
      item = {}
      item1.each {|k, v|
        item[rename_field1.fetch(k, k)] = v
      }
      common_values = item.values_at(*common_fields)
      val = hash
      common_values.each {|cv|
        val = val[cv]
      }
      val.each {|itemid|
        item0 = item.dup
        item1 = table2.get_item(itemid)
        item1.each {|k, v|
          item0[rename_field1.fetch(k, k)] = v
        }
        item0.delete("_itemid")
        if block_given?
          result.insert item0 if yield(item0)
        else
          result.insert item0
        end
      }
    }
    result
  end

  # call-seq:
  #   table.fmap!(field) {|itemid, value| new_value }
  def fmap!(field)
    each_itemid {|itemid|
      value = yield itemid, get_cell(itemid, field)
      set_cell(itemid, field, value)
    }
  end

  # call-seq:
  #   table.delete_field(field1, ...)
  #
  # deletes zero or more fields destructively.
  #
  # This method returns the number of fields which is not exists
  # before deletion.
  def delete_field(*fields)
    num_not_exist = 0
    fields.each {|f|
      f = f.to_s
      @tbl.delete(f) {|_| num_not_exist += 1 }
    }
    num_not_exist
  end
end
