class Table

  def Table.load_csv(filename, *header_fields)
    Table.parse_csv(File.read(filename), *header_fields)
  end

  def Table.parse_csv(csv, *header_fields)
    t = Table.new
    require 'csv'
    aa = []
    if defined? CSV::Reader
      # Ruby 1.8
      CSV::Reader.parse(csv) {|ary|
        ary = ary.map {|cell| cell.to_s }
        aa << ary
      }
    else
      # Ruby 1.9
      CSV.parse(csv) {|ary|
        ary = ary.map {|cell| cell.to_s }
        aa << ary
      }
    end
    if header_fields.empty?
      aa.shift while aa.first.all? {|elt| elt.nil? || elt == '' }
      header_fields = aa.shift
    end
    t = Table.new
    aa.each {|ary|
      h = {}
      header_fields.each_with_index {|f, i|
        h[f] = ary[i]
      }
      t.insert(h)
    }
    t
  end

  def generate_csv(out='', fields=nil, &block)
    if fields.nil?
      fields = @tbl.keys
    end
    require 'csv'
    rowids = all_rowids
    if block_given?
      rowids = yield(rowids)
    end
    if defined? CSV::Writer
      # Ruby 1.8
      CSV::Writer.generate(out) {|csvgen|
        csvgen << fields
        rowids.each {|rowid|
          csvgen << lookup_rowid(rowid, *fields)
        }
      }
    else
      # Ruby 1.9
      out << fields.to_csv
      rowids.each {|rowid|
        out << lookup_rowid(rowid, *fields).to_csv
      }
    end
  end
end
