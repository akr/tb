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

# Table represents a set of items.
# An item contains field values accessed by field names.
#
# A table can be visualized as follows.
#
#   _itemid f1  f2  f3
#   0       v01 v02 v03
#   1       v11 v12 v13
#   2       v21 v22 v23
#
# This table has 4 fields and 3 items:
# - fields: _itemid, f1, f2 and f3.
# - items: [0, v01, v02, v03], [1, v11, v12, v13] and [2, v21, v22, v23]
#
# The fields are strings.
# The field names starts with "_" is reserved.
# "_itemid" is a reserved field always defined to identify an item.
#
# Non-reserved fields can be defined by Table.new and Table#define_field.
# It is an error to access a field which is not defined.
#
# A value in an item is identified by an itemid and field name.
# A value for non-reserved fields can be any Ruby values.
# A value for _itemid is an non-negative integer and it is automatically allocated when a new item is inserted.
# It is an error to access an item by itemid which is not allocated.
#
class Table
  # :call-seq:
  #   Table.new
  #   Table.new(fields, values1, values2, ...)
  #
  # creates an instance of Table class.
  #
  # If the first argument, _fields_, is given, it should be an array of strings.
  # The strings are used as field names to define fields.
  # If the first argument is not given, only "_itemid" field is defined.
  #
  # If the second argument and subsequent arguments, valuesN, are given, they should be an array.
  # The arrays are used as items to define items.
  # A value in the array is used for a value of corresponding field defined by the first argument.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #     {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #     {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}>
  #   #     {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #
  def initialize(*args)
    @free_itemids = []
    @tbl = {"_itemid"=>[]}
    if !args.empty?
      args.first.each {|f|
        define_field(f)
      }
      insert_values(*args)
    end
  end

  def pretty_print(q) # :nodoc:
    q.object_group(self) {
      each_item {|item|
        q.breakable
        q.pp item
      }
    }
  end
  alias inspect pretty_print_inspect # :nodoc:

  def check_itemid(itemid)
    raise TypeError, "invalid itemid: #{itemid.inspect}" if itemid.kind_of?(Symbol) # Ruby 1.8 has Symbol#to_int.
    raise TypeError, "invalid itemid: #{itemid.inspect}" unless itemid.respond_to? :to_int
    itemid = itemid.to_int
    raise TypeError, "invalid itemid: #{itemid.inspect}" if !itemid.kind_of?(Integer)
    if itemid < 0 || @tbl["_itemid"].length <= itemid || @tbl["_itemid"][itemid] != itemid
      raise IndexError, "unexpected itemid: #{itemid.inspect}"
    end
    itemid
  end
  private :check_itemid

  def check_field(field)
    field = field.to_s
    unless @tbl.include? field
      raise ArgumentError, "field not defined: #{field.inspect}"
    end
    field
  end
  private :check_field

  # :call-seq:
  #   table.define_field(field)
  #   table.define_field(field) {|itemid| value_for_the_field }
  #
  # defines a new field.
  #
  # If no block is given, the initial value for the field is nil.
  #
  # If a block is given, the block is called for each itemid.
  # The return value of the block is used for the initial value of the field.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.define_field("namelen") {|itemid| t.get_cell(itemid, "fruit").length }
  #   pp t
  #   #=>  #<Table
  #   #     {"_itemid"=>0, "fruit"=>"apple", "color"=>"red", "namelen"=>5}
  #   #     {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow", "namelen"=>6}
  #   #     {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange", "namelen"=>6}>
  #
  def define_field(field)
    field = field.to_s
    if field.start_with?("_")
      raise ArgumentError, "field begins with underscore: #{field.inspect}"
    end
    if @tbl.include? field
      raise ArgumentError, "field already defined: #{field.inspect}"
    end
    @tbl[field] = []
    if block_given?
      each_itemid {|itemid|
        v = yield(itemid)
        if !v.nil?
          set_cell(itemid, field, v)
        end
      }
    end
  end

  # :call-seq:
  #   table.list_fields -> [field1, field2, ...]
  #
  # returns the list of field names as an array of strings.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.list_fields #=> ["_itemid", "fruit", "color"]
  #
  def list_fields
    @tbl.keys
  end

  # :call-seq:
  #   table.list_itemids -> [itemid1, itemid2, ...]
  #
  # returns the list of itemids as an array of integers.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.list_itemids #=> [0, 1, 2]
  #   
  def list_itemids
    @tbl["_itemid"].compact
  end

  # :call-seq:
  #   table.size
  #
  # returns the number of items.
  #
  #   t = Table.new %w[fruit],      
  #                 %w[apple],    
  #                 %w[banana],       
  #                 %w[orange]       
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple"}
  #   #    {"_itemid"=>1, "fruit"=>"banana"}
  #   #    {"_itemid"=>2, "fruit"=>"orange"}>
  #   p t.size
  #   #=> 3
  #
  def size
    @tbl["_itemid"].length - @free_itemids.length
  end

  # :call-seq:
  #   table.allocate_item -> fresh_itemid
  #
  # inserts an item.
  # All fields of the item are initialized to nil.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.allocate_item #=> 3
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #   #    {"_itemid"=>3}>
  #
  def allocate_item
    if @free_itemids.empty?
      itemid = @tbl["_itemid"].length
      @tbl["_itemid"] << itemid
    else
      itemid = @free_itemids.pop
      @tbl["_itemid"][itemid] = itemid
    end
    itemid
  end

  # :call-seq:
  #   table.set_cell(itemid, field, value) -> value
  #
  # sets the value of the cell identified by _itemid_ and _field_.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.set_cell(1, "color", "green")
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"green"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  def set_cell(itemid, field, value)
    itemid = check_itemid(itemid)
    field = check_field(field)
    raise ArgumentError, "can not set for reserved field: #{field.inspect}" if field.start_with?("_")
    ary = @tbl[field]
    ary[itemid] = value
  end

  # :call-seq:
  #   table.get_cell(itemid, field) -> value
  #
  # returns the value of the cell identified by _itemid_ and _field_.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.get_cell(1, "fruit") #=> "banana"
  #
  def get_cell(itemid, field)
    itemid = check_itemid(itemid)
    field = check_field(field)
    ary = @tbl[field]
    ary[itemid]
  end

  # :call-seq:
  #   table.delete_cell(itemid, field) -> oldvalue
  #
  # sets nil to the cell identified by _itemid_ and _field_.
  #
  # This method returns the old value.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange] 
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.delete_cell(1, "color") #=> "yellow"
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.get_cell(1, "color") #=> nil
  #
  def delete_cell(itemid, field)
    itemid = check_itemid(itemid)
    field = check_field(field)
    raise ArgumentError, "can not delete reserved field: #{field.inspect}" if field.start_with?("_") 
    ary = @tbl[field]
    old = ary[itemid]
    ary[itemid] = nil
    old
  end

  # :call-seq:
  #   table.delete_item(itemid) -> {field1=>value1, ...}
  #
  # deletes an item identified by _itemid_.
  #
  # This method returns nil.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.delete_item(1)
  #   #=> nil
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #
  def delete_item(itemid)
    itemid = check_itemid(itemid)
    @tbl.each {|f, ary|
      ary[itemid] = nil
    }
    @free_itemids.push itemid
    nil
  end

  # :call-seq:
  #   table.insert({field1=>value1, ...})
  #
  # inserts an item.
  #
  # This method returned the itemid of the inserted item.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   itemid = t.insert({"fruit"=>"grape", "color"=>"purple"})
  #   p itemid
  #   #=> 3
  #   pp t
  #   #=> #<Table
  #   #    {"_itemid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_itemid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_itemid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #   #    {"_itemid"=>3, "fruit"=>"grape", "color"=>"purple"}>
  #
  def insert(item)
    itemid = allocate_item
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

  # :call-seq:
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

  # :call-seq:
  #   table.update_item(itemid, {field1=>value1, ...}) -> nil
  def update_item(itemid, item)
    itemid = check_itemid(itemid)
    item.each {|f, v|
      f = check_field(f)
      set_cell(itemid, f, v)
    }
    nil
  end

  # :call-seq:
  #   table.get_values(itemid, field1, field2, ...) -> [value1, value2, ...]
  def get_values(itemid, *fields)
    itemid = check_itemid(itemid)
    fields.map {|f|
      f = check_field(f)
      get_cell(itemid, f)
    }
  end

  # :call-seq:
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

  # :call-seq:
  #   table.each_itemid {|itemid| ... }
  def each_itemid
    @tbl["_itemid"].each {|itemid|
      next if itemid.nil?
      yield itemid
    }
  end

  # :call-seq:
  #   table.to_a -> [{field1=>value1, ...}, ...]
  def to_a
    ary = []
    each_itemid {|itemid|
      ary << get_item(itemid)
    }
    ary
  end

  # :call-seq:
  #   table.each {|item| ... }
  #   table.each_item {|item| ... }
  def each_item
    each_itemid {|itemid|
      next if itemid.nil?
      yield get_item(itemid)
    }
  end
  alias each each_item

  # :call-seq:
  #   table.each_item_values(field1, ...) {|value1, ...| ... }
  def each_item_values(*fields)
    each_itemid {|itemid|
      vs = get_values(itemid, *fields)
      yield vs
    }
  end

  # :call-seq:
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
      value_field_list = value_field.map {|f| check_field(f) }
      gen_value = lambda {|all_values| all_values.last(value_field.length) }
    when true
      value_field_list = []
      gen_value = lambda {|all_values| true }
    else
      value_field_list = [check_field(value_field)]
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

  # :call-seq:
  #   table.make_hash_array(key_field1, key_field2, ..., value_field)
  def make_hash_array(*args)
    make_hash(*args) {|seed, value| !seed ? [value] : (seed << value) }
  end

  # :call-seq:
  #   table.make_hash_count(key_field1, key_field2, ...)
  def make_hash_count(*args)
    make_hash(*(args + [true])) {|seed, value| !seed ? 1 : seed+1 }
  end

  # :call-seq:
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

  # :call-seq:
  #   table1.natjoin2(table2, rename_field1={}, rename_field2={}) {|item| ... }
  def natjoin2(table2, rename_field1={}, rename_field2={})
    table1 = self
    fields1 = table1.list_fields.map {|f| rename_field1.fetch(f, f) }
    fields2 = table2.list_fields.map {|f| rename_field2.fetch(f, f) }
    fields1.delete("_itemid")
    fields2.delete("_itemid")
    common_fields = fields1 & fields2
    hash = table2.make_hash_array(*(common_fields + ["_itemid"]))
    result = Table.new(fields1 | fields2)
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

  # :call-seq:
  #   table.fmap!(field) {|itemid, value| new_value }
  def fmap!(field)
    each_itemid {|itemid|
      value = yield itemid, get_cell(itemid, field)
      set_cell(itemid, field, value)
    }
  end

  # :call-seq:
  #   table.delete_field(field1, ...)
  #
  # deletes zero or more fields destructively.
  #
  # This method returns nil.
  def delete_field(*fields)
    fields.each {|f|
      f = check_field(f)
      @tbl.delete(f)
    }
    nil
  end
end
