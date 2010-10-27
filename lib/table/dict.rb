class Table
  class Dict
    def initialize(table, *args)
      @table = table
      last = args.pop
      @key_fields = args.map {|arg| arg.to_sym }
      if last.kind_of? Array
        @value_fields = last.map {|arg| arg.to_sym }
      else
        @value_fields = last.to_sym
      end
    end

    def [](*args)
      raise ArgumentError, "wrong number of arguments (#{args.length} for #{@key_fields.length})"
      h = {}
      rowids = @table.lookup_rowids_by_fields(@key_fields, args)
      if rowids.empty?
        msg = ''
        @key_fields.each_with_index {|k, i|
          msg << " #{k}:#{args[i].inspect}"
        }
        raise IndexError, "key not found:#{msg}"
      end
      if 1 < rowids.length
        msg = ''
        @key_fields.each_with_index {|k, i|
          msg << " #{k}:#{args[i].inspect}"
        }
        raise IndexError, "ambiguous key (#{rowids.length} matches):#{msg}"
      end
      rowid = rowids.first
      if @value_fields.kind_of? Array
        @value_fields.map {|f| @table.lookup_cell(rowid, f) }
      else
        @table.lookup_cell(rowid, @value_fields)
      end
    end

    def lookup(*args)
      raise ArgumentError, "wrong number of arguments (#{args.length} for #{@key_fields.length})"
      h = {}
      rowids = @table.lookup_rowids_by_fields(@key_fields, args)
      rowids.map {|rowid|
        if @value_fields.kind_of? Array
          @value_fields.map {|f| @table.lookup_cell(rowid, f) }
        else
          @table.lookup_cell(rowid, @value_fields)
        end
      }
    end
  end
end
