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

# Table represents a set of records.
# A record contains field values accessed by field names.
#
# A table can be visualized as follows.
#
#   _recordid f1  f2  f3
#   0         v01 v02 v03
#   1         v11 v12 v13
#   2         v21 v22 v23
#
# This table has 4 fields and 3 records:
# - fields: _recordid, f1, f2 and f3.
# - records: [0, v01, v02, v03], [1, v11, v12, v13] and [2, v21, v22, v23]
#
# The fields are strings.
# The field names starts with "_" is reserved.
# "_recordid" is a reserved field always defined to identify a record.
#
# Non-reserved fields can be defined by Table.new and Table#define_field.
# It is an error to access a field which is not defined.
#
# A value in a record is identified by a recordid and field name.
# A value for non-reserved fields can be any Ruby values.
# A value for _recordid is an non-negative integer and it is automatically allocated when a new record is inserted.
# It is an error to access a record by recordid which is not allocated.
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
  # If the first argument is not given, only "_recordid" field is defined.
  #
  # If the second argument and subsequent arguments, valuesN, are given, they should be an array.
  # The arrays are used as records to define records.
  # A value in the array is used for a value of corresponding field defined by the first argument.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #     {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #     {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}>
  #   #     {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #
  def initialize(*args)
    @next_recordid = 0
    @recordid2index = {}
    @free_index = []
    @tbl = {"_recordid"=>[]}
    @field_list = ["_recordid"]
    if !args.empty?
      args.first.each {|f|
        define_field(f)
      }
      insert_values(*args)
    end
  end

  def pretty_print(q) # :nodoc:
    q.object_group(self) {
      each_recordid {|recordid|
        q.breakable
        record = get_record(recordid)
        fs = @field_list.reject {|f| get_cell(recordid, f).nil? }
        q.group(1, '{', '}') {
          q.seplist(fs, nil, :each) {|f|
            v = get_cell(recordid, f)
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
      }
    }
  end
  alias inspect pretty_print_inspect # :nodoc:

  def check_recordid_type(recordid)
    raise TypeError, "invalid recordid: #{recordid.inspect}" if recordid.kind_of?(Symbol) # Ruby 1.8 has Symbol#to_int.
    raise TypeError, "invalid recordid: #{recordid.inspect}" unless recordid.respond_to? :to_int
    recordid = recordid.to_int
    raise TypeError, "invalid recordid: #{recordid.inspect}" if !recordid.kind_of?(Integer)
    recordid
  end
  private :check_recordid_type

  def check_recordid(recordid)
    recordid = check_recordid_type(recordid)
    if !@recordid2index.include?(recordid)
      raise IndexError, "unexpected recordid: #{recordid.inspect}"
    end
    recordid
  end
  private :check_recordid

  def check_field_type(field)
    field.to_s
  end
  private :check_field_type

  def check_field(field)
    field = check_field_type(field)
    unless @tbl.include? field
      raise ArgumentError, "field not defined: #{field.inspect}"
    end
    field
  end
  private :check_field

  # :call-seq:
  #   table.define_field(field)
  #   table.define_field(field) {|recordid| value_for_the_field }
  #
  # defines a new field.
  #
  # If no block is given, the initial value for the field is nil.
  #
  # If a block is given, the block is called for each recordid.
  # The return value of the block is used for the initial value of the field.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.define_field("namelen") {|recordid| t.get_cell(recordid, "fruit").length }
  #   pp t
  #   #=>  #<Table
  #   #     {"_recordid"=>0, "fruit"=>"apple", "color"=>"red", "namelen"=>5}
  #   #     {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow", "namelen"=>6}
  #   #     {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange", "namelen"=>6}>
  #
  def define_field(field)
    field = check_field_type(field).dup.freeze
    if field.start_with?("_")
      raise ArgumentError, "field begins with underscore: #{field.inspect}"
    end
    if @tbl.include? field
      raise ArgumentError, "field already defined: #{field.inspect}"
    end
    @tbl[field] = []
    @field_list << field
    if block_given?
      each_recordid {|recordid|
        v = yield(recordid)
        if !v.nil?
          set_cell(recordid, field, v)
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
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.list_fields #=> ["_recordid", "fruit", "color"]
  #
  def list_fields
    @field_list.dup
  end

  # :call-seq:
  #   table.list_recordids -> [recordid1, recordid2, ...]
  #
  # returns the list of recordids as an array of integers.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.list_recordids #=> [0, 1, 2]
  #   
  def list_recordids
    @tbl["_recordid"].compact
  end

  # :call-seq:
  #   table.size
  #
  # returns the number of records.
  #
  #   t = Table.new %w[fruit],      
  #                 %w[apple],    
  #                 %w[banana],       
  #                 %w[orange]       
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple"}
  #   #    {"_recordid"=>1, "fruit"=>"banana"}
  #   #    {"_recordid"=>2, "fruit"=>"orange"}>
  #   p t.size
  #   #=> 3
  #
  def size
    @recordid2index.size
  end

  # :call-seq:
  #   table.allocate_record -> fresh_recordid
  #   table.allocate_record(recordid) -> recordid
  #
  # inserts a record.
  # All fields of the record are initialized to nil.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.allocate_record #=> 3
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #   #    {"_recordid"=>3}>
  #
  # If the optional recordid is specified and the recordid is not used in the
  # table, a record is allocated with the recordid.
  # If the specified recordid is already used, ArgumentError is raised.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.allocate_record(100)
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #   #    {"_recordid"=>100}>
  #
  def allocate_record(recordid=nil)
    if recordid.nil?
      recordid = @next_recordid
      @next_recordid += 1
    else
      recordid = check_recordid_type(recordid)
      if @recordid2index.include? recordid
        raise ArgumentError, "recordid already used: #{recordid.inspect}"
      end
      @next_recordid = recordid + 1 if @next_recordid <= recordid
    end
    if @free_index.empty?
      index = @tbl["_recordid"].length
    else
      index = @free_index.pop
    end
    @recordid2index[recordid] = index
    @tbl["_recordid"][index] = recordid
    recordid
  end

  # :call-seq:
  #   table.set_cell(recordid, field, value) -> value
  #
  # sets the value of the cell identified by _recordid_ and _field_.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.set_cell(1, "color", "green")
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"green"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  def set_cell(recordid, field, value)
    recordid = check_recordid(recordid)
    field = check_field(field)
    raise ArgumentError, "can not set for reserved field: #{field.inspect}" if field.start_with?("_")
    ary = @tbl[field]
    ary[@recordid2index[recordid]] = value
  end

  # :call-seq:
  #   table.get_cell(recordid, field) -> value
  #
  # returns the value of the cell identified by _recordid_ and _field_.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.get_cell(1, "fruit") #=> "banana"
  #
  def get_cell(recordid, field)
    recordid = check_recordid(recordid)
    field = check_field(field)
    ary = @tbl[field]
    ary[@recordid2index[recordid]]
  end

  # :call-seq:
  #   table.delete_cell(recordid, field) -> oldvalue
  #
  # sets nil to the cell identified by _recordid_ and _field_.
  #
  # This method returns the old value.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange] 
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.delete_cell(1, "color") #=> "yellow"
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.get_cell(1, "color") #=> nil
  #
  def delete_cell(recordid, field)
    recordid = check_recordid(recordid)
    field = check_field(field)
    raise ArgumentError, "can not delete reserved field: #{field.inspect}" if field.start_with?("_") 
    ary = @tbl[field]
    index = @recordid2index[recordid]
    old = ary[index]
    ary[index] = nil
    old
  end

  # :call-seq:
  #   table.delete_record(recordid) -> {field1=>value1, ...}
  #
  # deletes a record identified by _recordid_.
  #
  # This method returns nil.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.delete_record(1)
  #   #=> nil
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #
  def delete_record(recordid)
    recordid = check_recordid(recordid)
    index = @recordid2index.delete(recordid)
    @tbl.each {|f, ary|
      ary[index] = nil
    }
    @free_index.push index
    nil
  end

  # :call-seq:
  #   table.insert({field1=>value1, ...})
  #
  # inserts a record.
  # The record is represented as a hash which keys are field names.
  #
  # This method returned the recordid of the inserted record.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   recordid = t.insert({"fruit"=>"grape", "color"=>"purple"})
  #   p recordid
  #   #=> 3
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #   #    {"_recordid"=>3, "fruit"=>"grape", "color"=>"purple"}>
  #
  def insert(record)
    recordid = allocate_record
    update_record(recordid, record)
    recordid
  end

  # call-seq
  #   table.insert_values(fields, values1, values2, ...) -> [recordid1, recordid2, ...]
  #
  # inserts records.
  # The records are represented by fields and values separately.
  # The first argument specifies the field names as an array.
  # The second argument specifies the first record values as an array.
  # The third argument specifies the second record values and so on.
  # The third and subsequent arguments are optional.
  #
  # This method return an array of recordids.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.insert_values(["fruit", "color"], ["grape", "purple"], ["cherry", "red"])
  #   #=> [3, 4]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #   #    {"_recordid"=>3, "fruit"=>"grape", "color"=>"purple"}
  #   #    {"_recordid"=>4, "fruit"=>"cherry", "color"=>"red"}>
  #
  def insert_values(fields, *values_list)
    recordids = []
    values_list.each {|values|
      if values.length != fields.length
        raise ArgumentError, "#{fields.length} fields expected but #{values.length} values given"
      end
      h = {}
      fields.each_with_index {|f, i|
        v = values[i]
        h[f] = v
      }
      recordids << insert(h)
    }
    recordids
  end

  # :call-seq:
  #   table1.concat(table2, table3, ...) -> table1
  #
  # concatenates argument tables destructively into _table1_.
  #
  # This method returns _table1_.
  #
  #   t1 = Table.new %w[fruit color],
  #                  %w[apple red]
  #   t2 = Table.new %w[fruit color],
  #                  %w[banana yellow],
  #                  %w[orange orange]
  #   pp t1
  #   #=> #<Table {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}>
  #   pp t2
  #   #=> #<Table
  #        {"_recordid"=>0, "fruit"=>"banana", "color"=>"yellow"}
  #        {"_recordid"=>1, "fruit"=>"orange", "color"=>"orange"}>
  #   t1.concat(t2)
  #   pp t1
  #   #=> #<Table
  #        {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #        {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #        {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #
  def concat(*tables)
    tables.each {|t|
      t.each_record {|record|
        record.delete "_recordid"
        self.insert record
      }
    }
    self
  end

  # :call-seq:
  #   table.update_record(recordid, {field1=>value1, ...}) -> nil
  #
  # updates the record specified by _recordid_.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.update_record(1, {"color"=>"green"}) 
  #   #=> nil
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"green"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #
  def update_record(recordid, record)
    recordid = check_recordid(recordid)
    record.each {|f, v|
      f = check_field(f)
      set_cell(recordid, f, v)
    }
    nil
  end

  # :call-seq:
  #   table.get_values(recordid, field1, field2, ...) -> [value1, value2, ...]
  #
  # extracts specified fields of the specified record.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.get_values(1, "fruit", "color")
  #   #=> ["banana", "yellow"]
  #   p t.get_values(0, "fruit")
  #   #=> ["apple"]
  #
  def get_values(recordid, *fields)
    recordid = check_recordid(recordid)
    fields.map {|f|
      f = check_field(f)
      get_cell(recordid, f)
    }
  end

  # :call-seq:
  #   table.get_record(recordid) -> {field1=>value1, ...}
  #
  # get the record specified by _recordid_ as a hash.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.get_record(1)                    
  #   #=> {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #
  def get_record(recordid)
    result = {}
    index = @recordid2index[recordid]
    @tbl.each {|f, ary|
      v = ary[index]
      next if v.nil?
      result[f] = v
    }
    result
  end

  # :call-seq:
  #   table.each_recordid {|recordid| ... }
  #
  # iterates over all records and yield the recordids of them.
  #
  # This method returns nil.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.each_recordid {|recordid| p recordid }
  #   #=> 0
  #   #   1
  #   #   2
  #
  def each_recordid
    @tbl["_recordid"].each {|recordid|
      next if recordid.nil?
      yield recordid
    }
    nil
  end

  # :call-seq:
  #   table.to_a -> [{field1=>value1, ...}, ...]
  #
  # returns an array containing all records as hashes.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   pp t.to_a                         
  #   #=> [{"_recordid"=>0, "fruit"=>"apple", "color"=>"red"},
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"},
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}]
  #
  def to_a
    ary = []
    each_recordid {|recordid|
      ary << get_record(recordid)
    }
    ary
  end

  # :call-seq:
  #   table.each {|record| ... }
  #   table.each_record {|record| ... }
  #
  # iterates over all records and yields them as hashes.
  #
  # This method returns nil.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.each_record {|record| p record }   
  #   #=> {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #   {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #   {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #
  def each_record
    each_recordid {|recordid|
      next if recordid.nil?
      yield get_record(recordid)
    }
    nil
  end
  alias each each_record

  # :call-seq:
  #   table.each_record_values(field1, ...) {|value1, ...| ... }
  def each_record_values(*fields)
    each_recordid {|recordid|
      vs = get_values(recordid, *fields)
      yield vs
    }
  end

  # :call-seq:
  #   table.hashtree(key_field1, key_field2, ..., value_field, :seed=>initial_seed) {|seed, value| ... } -> hash
  #
  # hashtree takes following arguments:
  # - one or more key fields
  # - value field which can be a single field name or an array of field names
  # -- a single field
  # -- an array of field names
  # -- true
  # - optional option hash which may contains:
  # -- :seed option
  #
  # hashtree takes optional block.
  #
  def hashtree(*args)
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
    each_record_values(*all_fields) {|all_values|
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
  #   table.hashtree_array(key_field1, key_field2, ..., value_field)
  def hashtree_array(*args)
    hashtree(*args) {|seed, value| !seed ? [value] : (seed << value) }
  end

  # :call-seq:
  #   table.hashtree_count(key_field1, key_field2, ...)
  def hashtree_count(*args)
    hashtree(*(args + [true])) {|seed, value| !seed ? 1 : seed+1 }
  end

  # :call-seq:
  #   table.reject {|record| ... }
  def reject
    t = Table.new
    each_record {|record|
      if !yield(record)
        record.delete "_recordid"
        t.insert record
      end
    }
    t
  end

  # :call-seq:
  #   table1.natjoin2(table2, rename_field1={}, rename_field2={}) {|record| ... }
  def natjoin2(table2, rename_field1={}, rename_field2={})
    table1 = self
    fields1 = table1.list_fields.map {|f| rename_field1.fetch(f, f) }
    fields2 = table2.list_fields.map {|f| rename_field2.fetch(f, f) }
    fields1.delete("_recordid")
    fields2.delete("_recordid")
    common_fields = fields1 & fields2
    hash = table2.hashtree_array(*(common_fields + ["_recordid"]))
    result = Table.new(fields1 | fields2)
    table1.each_record {|record1|
      record = {}
      record1.each {|k, v|
        record[rename_field1.fetch(k, k)] = v
      }
      common_values = record.values_at(*common_fields)
      val = hash
      common_values.each {|cv|
        val = val[cv]
      }
      val.each {|recordid|
        record0 = record.dup
        record1 = table2.get_record(recordid)
        record1.each {|k, v|
          record0[rename_field1.fetch(k, k)] = v
        }
        record0.delete("_recordid")
        if block_given?
          result.insert record0 if yield(record0)
        else
          result.insert record0
        end
      }
    }
    result
  end

  # :call-seq:
  #   table.fmap!(field) {|recordid, value| new_value }
  def fmap!(field)
    each_recordid {|recordid|
      value = yield recordid, get_cell(recordid, field)
      set_cell(recordid, field, value)
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
      raise ArgumentError, "can not delete reserved field: #{f.inspect}" if f.start_with?("_") 
      @tbl.delete(f)
      @field_list.delete(f)
    }
    nil
  end

  # :call-seq:
  #   table.rename_field({old_field1=>new_field1, ...})
  #
  # creates a new table which field names are renamed.
  #
  #   t = Table.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Table
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   pp t.rename_field("fruit"=>"food")
  #   #=> #<Table
  #   #    {"_recordid"=>0, "food"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "food"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "food"=>"orange", "color"=>"orange"}>
  #
  def rename_field(rename_hash)
    rh = {}
    rename_hash.each {|of, nf|
      of = check_field(of)
      nf = check_field_type(nf)
      rh[of] = nf
    }
    result = Table.new
    next_recordid = @next_recordid
    recordid2index = @recordid2index
    free_index = @free_index
    tbl = @tbl
    result.instance_eval {
      @tbl.clear # delete _recordid.
      tbl.each {|old_field, ary|
        new_field = rh.fetch(old_field) {|f| f }
        if @tbl.include? new_field
          raise ArgumentError, "field name crash: #{new_field.inspect}"
        end
        @tbl[new_field] = ary.dup
      }
      @next_recordid = next_recordid
      @recordid2index.replace recordid2index
      @free_index.replace free_index
    }
    result
  end
end
