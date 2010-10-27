class Table
  def initialize
    @free_rowids = []
    @tbl = {"_rowid"=>[]}
  end

  def make_dict(*args)
    Table::Dict.new(self, *args)
  end

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

  def insert(hash)
    rowid = allocate_rowid
    update_rowid(rowid, hash)
    rowid
  end

  def update_rowid(rowid, hash)
    check_rowid(rowid)
    hash.each {|f, v|
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
end
