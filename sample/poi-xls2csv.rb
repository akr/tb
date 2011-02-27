#!/usr/bin/jruby

$KCODE = 'u'

require 'table'
require 'optparse'

require 'jakarta-poi.jar'
Java.include_class 'org.apache.poi.hssf.usermodel.HSSFWorkbook'
Java.include_class 'org.apache.poi.hssf.usermodel.HSSFDateUtil'
Java.include_class 'org.apache.poi.hssf.usermodel.HSSFCellStyle'

$opt_all_sheets = false
$opt_prepend_filename = false
$opt_mergecells = 'fill'

op = OptionParser.new
op.def_option('-h', 'show help message') { puts op; exit true }
op.def_option('-a', 'convert all sheets (sheet name is prepended to all rows)') { $opt_all_sheets = true }
op.def_option('-f', 'prepend filename for all rows') { $opt_prepend_filename = true }
op.def_option('--mergecells=mode', '"fill" or "topleft"') {|v| $opt_mergecells = v }
op.parse!(ARGV)

# http://sc.openoffice.org/excelfileformat.pdf 5.49 FORMAT
ExcelDateStyles = [
  15, 16, 17, 18, 19, 20, 21, 27, 28, 29,
  30, 31, 32, 33, 34, 35, 36, 45, 46, 47, 49,
  50, 51, 52, 53, 54, 55, 56, 57, 58,
  1432, 2232,
]
ExcelDateStylesHash = {}
ExcelDateStyles.each {|i| ExcelDateStylesHash[i] = true }

BordersName2Num = {}
BordersNum2Name = {}
Java::HSSFCellStyle::constants.each {|n|
  next if /\ABORDER_/ !~ n
  suffix = $'
  BordersNum2Name[Java::HSSFCellStyle::const_get(n)] = suffix
  BordersName2Num[suffix] = Java::HSSFCellStyle::const_get(n)
}

def convert_single_cell(cell)
  style = cell.getCellStyle
  case cell.getCellType
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_NUMERIC
    if Java::HSSFDateUtil.isCellDateFormatted(cell) ||
       ExcelDateStylesHash[style.getDataFormat]
      d = cell.getDateCellValue
      val = "%d-%02d-%02d %02d:%02d:%02d" % [
	d.getYear+1900, d.getMonth+1, d.getDate, d.getHours, d.getMinutes, d.getSeconds
      ]
    else
      val = cell.getNumericCellValue
    end
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_STRING
    str = cell.getRichStringCellValue.getString
    val = str
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_FORMULA
    val = cell.getCellFormula
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_BLANK
    val = nil
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_BOOLEAN
    val = cell.getBooleanCellValue
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_ERROR
    val = "\#ERR#{cell.getErrorCellValue}"
  else
    raise "unexpected cell type: #{cell.getCellType.inspect}"
  end
  val
end

def convert_cell(sheet, merged, row, x, y)
  if merged[[x,y]]
    x1, y1, x2, y2 = merged[[x,y]]
    topleft_cell = sheet.getRow(y1).getCell(x1)
    if $opt_mergecells == 'topleft'
      if x == x1 && y == y1
	val = convert_single_cell(topleft_cell)
      else
	val = nil
      end
    else
      val = convert_single_cell(topleft_cell)
    end
  elsif (cell = row.getCell(x))
#    style = cell.getCellStyle
#    p [:border,
#       BordersNum2Name[style.getBorderRight],
#       BordersNum2Name[style.getBorderTop],
#       BordersNum2Name[style.getBorderLeft],
#       BordersNum2Name[style.getBorderBottom]]
    val = convert_single_cell(cell)
  else
    val = nil
  end
  val
end

def get_merged_regions(sheet)
  merged = {}
  sheet.getNumMergedRegions.times {|j|
    r = sheet.getMergedRegionAt(j)
    x1 = r.getColumnFrom
    y1 = r.getRowFrom
    x2 = r.getColumnTo
    y2 = r.getRowTo
    rid = [x1, y1, x2, y2]
    y1.upto(y2) {|y|
      x1.upto(x2) {|x|
	merged[[x,y]] = rid
      }
    }
  }
  merged
end

def convert_sheet(filename, book, i, csvgen)
  sheet = book.getSheetAt(i)
  sheetname = book.getSheetName(i)
  merged = get_merged_regions(sheet)
  rownums = sheet.getFirstRowNum..sheet.getLastRowNum
  min_firstcol = rownums.map {|y| sheet.getRow(y).getFirstCellNum }.min
  max_lastcol = rownums.map {|y| sheet.getRow(y).getLastCellNum-1 }.max
  rownums.each {|y|
    record = []
    row = sheet.getRow(y)
    row.getFirstCellNum.upto(row.getLastCellNum-1) {|x|
      val = convert_cell(sheet, merged, row, x, y)
      record[x-min_firstcol] = val if !val.nil?
    }
    if $opt_all_sheets
      record.unshift sheetname
    end
    if $opt_prepend_filename
      record.unshift filename
    end
    csvgen << record
  }
end

def convert_book(filename, input, csvgen)
  book = Java::HSSFWorkbook.new(input)
  if $opt_all_sheets
    0.upto(book.getNumberOfSheets-1) {|i|
      convert_sheet(filename, book, i, csvgen)
    }
  else
    convert_sheet(filename, book, 0, csvgen)
  end
end

Table.csv_stream_output(STDOUT) {|csvgen|
  argv = ARGV.empty? ? ['-'] : ARGV
  argv.each {|filename|
    if filename == '-'
      input = java.lang.System.in
    else
      input = java.io.FileInputStream.new(filename)
    end
    convert_book(filename, input, csvgen)
  }
}

exit true
