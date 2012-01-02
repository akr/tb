# lib/tb/basic.rb - basic fetures for table library
#
# Copyright (C) 2010-2012 Tanaka Akira  <akr@fsij.org>
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

require 'pp'

# Tb represents a set of records.
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
# Non-reserved fields can be defined by Tb.new and Tb#define_field.
# It is an error to access a field which is not defined.
#
# A value in a record is identified by a recordid and field name.
# A value for non-reserved fields can be any Ruby values.
# A value for _recordid is an non-negative integer and it is automatically allocated when a new record is inserted.
# It is an error to access a record by recordid which is not allocated.
#
class Tb
  include Tb::Enum

  # :call-seq:
  #   Tb.new
  #   Tb.new(fields, values1, values2, ...)
  #
  # creates an instance of Tb class.
  #
  # If the first argument, _fields_, is given, it should be an array of strings.
  # The strings are used as field names to define fields.
  #
  # The field names begins with underscore, "_", are reserved.
  # Currently, "_recordid" field is defined automatically.
  #
  # If the second argument and subsequent arguments, valuesN, are given, they should be an array.
  # The arrays are used as records to define records.
  # A value in the array is used for a value of corresponding field defined by the first argument.
  #
  #   t = Tb.new %w[fruit color],
  #                 %w[apple red],
  #                 %w[banana yellow],
  #                 %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #     {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #     {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}>
  #   #     {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #
  def initialize(*args)
    @next_recordid = 0
    @recordid2index = {}
    @free_index = []
    @tbl = {"_recordid"=>[]}
    @field_list = ["_recordid".freeze]
    if !args.empty?
      args.first.each {|f|
        define_field(f)
      }
      insert_values(*args)
    end
  end

  # :call-seq:
  #   table.replace(table2)
  #
  # replaces the contents of _table_ same as _table2_.
  def replace(tbl2)
    raise TypeError, "a Tb expected but #{tbl2.inspect}" unless Tb === tbl2
    @next_recordid = tbl2.instance_variable_get(:@next_recordid)
    @recordid2index = tbl2.instance_variable_get(:@recordid2index).dup
    @free_index = tbl2.instance_variable_get(:@free_index).dup
    @tbl = Hash[tbl2.instance_variable_get(:@tbl).map {|k, v| [k, v.dup] }]
    @field_list = tbl2.instance_variable_get(:@field_list).dup
  end

  def pretty_print(q) # :nodoc:
    q.object_group(self) {
      each_recordid {|recordid|
        q.breakable
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
    raise TypeError, "invalid field name: #{field.inspect}" if field.nil?
    field = field.to_s
    raise TypeError, "invalid field name: #{field.inspect}" if !field.kind_of?(String)
    field
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
  #   table.define_field(field) {|record| value_for_the_field }
  #
  # defines a new field.
  #
  # If no block is given, the initial value for the field is nil.
  #
  # If a block is given, the block is called for each record.
  # The return value of the block is used for the initial value of the field.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.define_field("namelen") {|record| record["fruit"].length }
  #   pp t
  #   #=>  #<Tb
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
      each_record {|record|
        v = yield(record)
        if !v.nil?
          record[field] = v
        end
      }
    end
  end

  # :call-seq:
  #   table.has_field?(field) -> true or false
  #
  # returns true if the field specified by the argument is exist.
  #
  #   t = Tb.new %w[fruit color], 
  #              %w[apple red], 
  #              %w[banana yellow], 
  #              %w[orange orange] 
  #   pp t 
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.has_field?("fruit") #=> true
  #   p t.has_field?("foo") #=> false
  #
  def has_field?(field)
    field = check_field_type(field)
    @tbl.has_key?(field)
  end

  # :call-seq:
  #   table.list_fields -> [field1, field2, ...]
  #
  # returns the list of non-reserved field names as an array of strings.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.list_fields #=> ["fruit", "color"]
  #
  def list_fields
    @field_list.reject {|f| f.start_with?("_") }
  end

  # :call-seq:
  #   table.list_fields_all -> [field1, field2, ...]
  #
  # returns the list of reserved and non-reserved field names as an array of strings.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.list_fields_all #=> ["_recordid", "fruit", "color"]
  #
  def list_fields_all
    @field_list.dup
  end

  # :call-seq:
  #   table.reorder_fields!(fields)
  #
  # reorder the fields.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   p t.list_fields
  #   #=> ["fruit", "color"]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.reorder_fields! %w[color fruit]
  #   p t.list_fields
  #   #=> ["color", "fruit"]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "color"=>"red", "fruit"=>"apple"}
  #   #    {"_recordid"=>1, "color"=>"yellow", "fruit"=>"banana"}
  #   #    {"_recordid"=>2, "color"=>"orange", "fruit"=>"orange"}>
  #
  def reorder_fields!(fields)
    reserved, non_resreved = @field_list.reject {|f| fields.include? f }.partition {|f| f.start_with?("_") }
    fs = reserved + fields + non_resreved
    @field_list = @field_list.sort_by {|f| fs.index(f) }
  end

  # :call-seq:
  #   table.list_recordids -> [recordid1, recordid2, ...]
  #
  # returns the list of recordids as an array of integers.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
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
  #   t = Tb.new %w[fruit],      
  #              %w[apple],    
  #              %w[banana],       
  #              %w[orange]       
  #   pp t
  #   #=> #<Tb
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
  #   table.allocate_recordid -> fresh_recordid
  #   table.allocate_recordid(recordid) -> recordid
  #
  # inserts a record and returns its identifier.
  # All fields of the record are initialized to nil.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.allocate_recoridd #=> 3
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #   #    {"_recordid"=>3}>
  #
  # If the optional recordid is specified and the recordid is not used in the
  # table, a record is allocated with the recordid.
  # If the specified recordid is already used, ArgumentError is raised.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.allocate_recordid(100)
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #   #    {"_recordid"=>100}>
  #
  def allocate_recordid(recordid=nil)
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
  #   table.allocate_record(recordid=nil)
  #
  # allocates a record.
  #
  # If the optional argument, _recordid_, is specified,
  # the allocated record will have the recordid.
  # If _recordid_ is already used, ArgumentError is raised.
  def allocate_record(recordid=nil)
    Tb::Record.new(self, allocate_recordid(recordid))
  end

  # :call-seq:
  #   table.set_cell(recordid, field, value) -> value
  #
  # sets the value of the cell identified by _recordid_ and _field_.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.set_cell(1, "color", "green")
  #   pp t
  #   #=> #<Tb
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
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
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
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange] 
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.delete_cell(1, "color") #=> "yellow"
  #   pp t
  #   #=> #<Tb
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
  #   table.delete_recordid(recordid) -> nil
  #
  # deletes a record identified by _recordid_.
  #
  # This method returns nil.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.delete_recordid(1)
  #   #=> nil
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #
  def delete_recordid(recordid)
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
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   recordid = t.insert({"fruit"=>"grape", "color"=>"purple"})
  #   p recordid
  #   #=> 3
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #   #    {"_recordid"=>3, "fruit"=>"grape", "color"=>"purple"}>
  #
  def insert(record)
    recordid = allocate_recordid
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
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.insert_values(["fruit", "color"], ["grape", "purple"], ["cherry", "red"])
  #   #=> [3, 4]
  #   pp t
  #   #=> #<Tb
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
  # The reserved field (_recordid) in the argument tables is ignored.
  #
  # This method returns _table1_.
  #
  #   t1 = Tb.new %w[fruit color],
  #               %w[apple red]
  #   t2 = Tb.new %w[fruit color],
  #               %w[banana yellow],
  #               %w[orange orange]
  #   pp t1
  #   #=> #<Tb {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}>
  #   pp t2
  #   #=> #<Tb
  #        {"_recordid"=>0, "fruit"=>"banana", "color"=>"yellow"}
  #        {"_recordid"=>1, "fruit"=>"orange", "color"=>"orange"}>
  #   t1.concat(t2)
  #   pp t1
  #   #=> #<Tb
  #        {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #        {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #        {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #
  def concat(*tables)
    tables.each {|t|
      t.each_record {|record|
        record = record.to_h
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
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.update_record(1, {"color"=>"green"}) 
  #   #=> nil
  #   pp t
  #   #=> #<Tb
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
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
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
  #   table.get_record(recordid) -> record
  #
  # get the record specified by _recordid_ as a hash.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   p t.get_record(1)                    
  #   #=> #<Tb::Record: "_recordid"=>1, "fruit"=>"banana", "color"=>"yellow">
  #
  def get_record(recordid)
    recordid = check_recordid(recordid)
    Tb::Record.new(self, recordid)
  end

  # :call-seq:
  #   table.each_field {|field| ... }
  #
  # iterates over the non-reserved field names of the table.
  #
  #   t = Tb.new %w[fruit color],    
  #              %w[apple red], 
  #              %w[banana yellow], 
  #              %w[orange orange] 
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.each_field {|f| p f }
  #   #=> "fruit"
  #   #   "color"
  #
  def each_field
    @field_list.each {|f|
      next if f.start_with?("_")
      yield f
    }
    nil
  end

  # :call-seq:
  #   table.each_field_with_reserved {|field| ... }
  #
  # iterates over the reserved and non-reserved field names of the table.
  #
  #   t = Tb.new %w[fruit color],    
  #              %w[apple red], 
  #              %w[banana yellow], 
  #              %w[orange orange] 
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.each_field {|f| p f }
  #   #=> "_recordid"
  #   #   "fruit"
  #   #   "color"
  #
  def each_field_with_reserved
    @field_list.each {|f| yield f }
    nil
  end

  # :call-seq:
  #   table.each_recordid {|recordid| ... }
  #
  # iterates over all records and yield the recordids of them.
  #
  # This method returns nil.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
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
  #   table.to_a -> [record1, ...]
  #
  # returns an array containing all records as Tb::Record objects.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   pp t.to_a                         
  #   #=> [#<Tb::Record: "fruit"=>"apple", "color"=>"red">,
  #   #    #<Tb::Record: "fruit"=>"banana", "color"=>"yellow">,
  #   #    #<Tb::Record: "fruit"=>"orange", "color"=>"orange">]
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
  # iterates over all records and yields them as Tb::Record object.
  #
  # This method returns nil.
  #
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   t.each_record {|record| p record }   
  #   #=> #<Tb::Record: "fruit"=>"apple", "color"=>"red">
  #   #   #<Tb::Record: "fruit"=>"banana", "color"=>"yellow">
  #   #   #<Tb::Record: "fruit"=>"orange", "color"=>"orange">
  #
  def each_record
    each_recordid {|recordid|
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
  #   table.filter {|record| ... }
  def filter
    t = Tb.new list_fields
    each_record {|record|
      if yield(record)
        t.insert record
      end
    }
    t
  end

  # :call-seq:
  #   table1.natjoin2(table2)
  def natjoin2(table2)
    table1 = self
    fields1 = table1.list_fields
    fields2 = table2.list_fields
    common_fields = fields1 & fields2
    total_fields = fields1 | fields2
    unique_fields2 = fields2 - common_fields
    h = {}
    table2.each {|rec2|
      k = rec2.values_at(*common_fields)
      (h[k] ||= []) << rec2
    }
    result = Tb.new(fields1 | fields2)
    table1.each {|rec1|
      k = rec1.values_at(*common_fields)
      rec2_list = h[k]
      next if !rec2_list
      values = rec1.values_at(*fields1)
      rec2_list.each {|rec2|
        result.insert_values total_fields, values + rec2.values_at(*unique_fields2)
      }
    }
    result
  end

  # :call-seq:
  #   table1.natjoin2_outer(table2, missing=nil, retain_left=true, retain_right=true)
  def natjoin2_outer(table2, missing=nil, retain_left=true, retain_right=true)
    table1 = self
    fields1 = table1.list_fields
    fields2 = table2.list_fields
    common_fields = fields1 & fields2
    total_fields = fields1 | fields2
    unique_fields2 = fields2 - common_fields
    fields2_extended = total_fields.map {|f| fields2.include?(f) ? f : nil }
    h = {}
    table2.each {|rec2|
      k = rec2.values_at(*common_fields)
      (h[k] ||= []) << rec2
    }
    result = Tb.new(total_fields)
    ids2 = {}
    table1.each {|rec1|
      k = rec1.values_at(*common_fields)
      rec2_list = h[k]
      values = rec1.values_at(*fields1)
      if !rec2_list || rec2_list.empty? 
        if retain_left
	  result.insert_values total_fields, values + unique_fields2.map { missing }
	end
      else
        rec2_list.each {|rec2|
          ids2[rec2['_recordid']] = true
          result.insert_values total_fields, values + rec2.values_at(*unique_fields2)
        }
      end
    }
    if retain_right
      table2.each {|rec2|
	if !ids2[rec2['_recordid']]
	  result.insert_values total_fields, fields2_extended.map {|f| f ? rec2[f] : missing }
	end
      }
    end
    result
  end

  # :call-seq:
  #   table.fmap!(field) {|record, value| new_value }
  def fmap!(field)
    each_recordid {|recordid|
      value = yield get_record(recordid), get_cell(recordid, field)
      set_cell(recordid, field, value)
    }
  end

  # :call-seq:
  #   table.delete_field(field1, ...) -> nil
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
  #   t = Tb.new %w[fruit color],
  #              %w[apple red],
  #              %w[banana yellow],
  #              %w[orange orange]
  #   pp t
  #   #=> #<Tb
  #   #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #   #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #   #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #   pp t.rename_field("fruit"=>"food")
  #   #=> #<Tb
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
    result = Tb.new
    field_list = self.list_fields
    field_list.each {|of|
      nf = rh.fetch(of, of)
      result.define_field(nf)
    }
    each_recordid {|recordid|
      values = get_values(recordid, *field_list)
      result.allocate_recordid(recordid)
      field_list.each_with_index {|of, i|
        nf = rh.fetch(of, of)
        result.set_cell(recordid, nf, values[i])
      }
    }
    result
  end

  # :call-seq:
  #   table.reorder_records_by {|rec| ... }
  #
  # creates a new table object which has same records as _table_ but
  # the order of the records are sorted.
  #
  # The sort order is defined as similar manner to Enumerable#sort_by.
  #
  #  t = Tb.new %w[fruit color],
  #             %w[apple red],
  #             %w[banana yellow],
  #             %w[orange orange]
  #  pp t
  #  #=> #<Tb
  #  #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #  #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}
  #  #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}>
  #
  #  pp t.reorder_records_by {|rec| rec["color"] }
  #  #=> #<Tb
  #  #    {"_recordid"=>2, "fruit"=>"orange", "color"=>"orange"}
  #  #    {"_recordid"=>0, "fruit"=>"apple", "color"=>"red"}
  #  #    {"_recordid"=>1, "fruit"=>"banana", "color"=>"yellow"}>
  #
  def reorder_records_by(&b)
    result = Tb.new self.list_fields
    self.sort_by(&b).each {|rec|
      recordid = result.allocate_recordid(rec["_recordid"])
      result.update_record(recordid, rec)
    }
    result
  end
end
