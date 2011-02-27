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
$opt_border = false

op = OptionParser.new
op.def_option('-h', 'show help message') { puts op; exit true }
op.def_option('-a', 'convert all sheets (sheet name is prepended to all rows)') { $opt_all_sheets = true }
op.def_option('-f', 'prepend filename for all rows') { $opt_prepend_filename = true }
op.def_option('--mergecells=mode', '"fill" or "topleft"') {|v| $opt_mergecells = v }
op.def_option('--border', 'extract borders') { $opt_border = true }
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

BorderName2Num = {}
BorderNum2Name = {}
Java::HSSFCellStyle::constants.each {|n|
  next if /\ABORDER_/ !~ n
  suffix = $'
  BorderNum2Name[Java::HSSFCellStyle::const_get(n)] = suffix
  BorderName2Num[suffix] = Java::HSSFCellStyle::const_get(n)
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

def convert_horizontal_borders(sheet, upper_y, min_firstcol)
  rownums = sheet.getFirstRowNum..sheet.getLastRowNum
  lower_y = upper_y+1
  min = 0
  max = 0
  if rownums.include? upper_y
    upper_row = sheet.getRow(upper_y)
    upper_cellrange = upper_row.getFirstCellNum...upper_row.getLastCellNum
    if max < (upper_cellrange.end-min_firstcol)*2
      max = (upper_cellrange.end-min_firstcol)*2
    end
  end
  if rownums.include? lower_y
    lower_row = sheet.getRow(lower_y)
    lower_cellrange = lower_row.getFirstCellNum...lower_row.getLastCellNum
    if max < (lower_cellrange.end-min_firstcol)*2
      max = (lower_cellrange.end-min_firstcol)*2
    end
  end
  ary = []
  min.upto(max) {|i|
    if (i & 1) == 0
      # border
      right_x = min_firstcol + i / 2
      left_x = right_x - 1
      upper_line = lower_line = left_line = right_line = false
      if upper_row
	if !upper_line && upper_cellrange.include?(left_x) &&
	   (upperleft_cell = upper_row.getCell(left_x)) &&
	   upperleft_cell.getCellStyle.getBorderRight != Java::HSSFCellStyle::BORDER_NONE
	  upper_line = true
	end
        if !upper_line && upper_cellrange.include?(right_x) &&
	   (upperright_cell = upper_row.getCell(right_x)) &&
	   upperright_cell.getCellStyle.getBorderLeft != Java::HSSFCellStyle::BORDER_NONE
	  upper_line = true
	end
	if !left_line && upper_cellrange.include?(left_x) &&
	   (upperleft_cell = upper_row.getCell(left_x)) &&
	   upperleft_cell.getCellStyle.getBorderBottom != Java::HSSFCellStyle::BORDER_NONE
	  left_line = true
	end
	if !right_line && upper_cellrange.include?(right_x) &&
	   (upperright_cell = upper_row.getCell(right_x)) &&
	   upperright_cell.getCellStyle.getBorderBottom != Java::HSSFCellStyle::BORDER_NONE
	  right_line = true
	end
      end
      if lower_row
	if !lower_line && lower_cellrange.include?(left_x) &&
	   (lowerleft_cell = lower_row.getCell(left_x)) &&
	   lowerleft_cell.getCellStyle.getBorderRight != Java::HSSFCellStyle::BORDER_NONE
	  lower_line = true
	end
        if !lower_line && lower_cellrange.include?(right_x) &&
	   (lowerright_cell = lower_row.getCell(right_x)) &&
	   lowerright_cell.getCellStyle.getBorderLeft != Java::HSSFCellStyle::BORDER_NONE
	  lower_line = true
	end
	if !left_line && lower_cellrange.include?(left_x) &&
	   (lowerleft_cell = lower_row.getCell(left_x)) &&
	   lowerleft_cell.getCellStyle.getBorderTop != Java::HSSFCellStyle::BORDER_NONE
	  left_line = true
	end
	if !right_line && lower_cellrange.include?(right_x) &&
	   (lowerright_cell = lower_row.getCell(right_x)) &&
	   lowerright_cell.getCellStyle.getBorderTop != Java::HSSFCellStyle::BORDER_NONE
	  right_line = true
	end
      end
      if upper_line && lower_line && !left_line && !right_line
        joint = '|'
      elsif !upper_line && !lower_line && left_line && right_line
        joint = '-'
      elsif upper_line || lower_line || left_line || right_line
        joint = '+'
      else
        joint = nil
      end
      #joint ||= ' '
      ary << joint
    else
      # cell
      hborder = nil
      cell_x = min_firstcol + i / 2
      if !hborder && upper_row && upper_cellrange.include?(cell_x) &&
         (upper_cell = upper_row.getCell(cell_x)) &&
	 upper_cell.getCellStyle.getBorderBottom != Java::HSSFCellStyle::BORDER_NONE
	hborder = '-'
      end
      if !hborder && lower_row && lower_cellrange.include?(cell_x) &&
         (lower_cell = lower_row.getCell(cell_x)) &&
	 lower_cell.getCellStyle.getBorderTop != Java::HSSFCellStyle::BORDER_NONE
	hborder = '-'
      end
      #hborder ||= ' '
      ary << hborder
    end
  }
  ary
end

def convert_vertical_border(sheet, y, left_x)
  right_x = left_x+1
  row = sheet.getRow(y)
  cellrange = row.getFirstCellNum...row.getLastCellNum
  vborder = nil
  if !vborder && cellrange.include?(left_x) &&
     (left_cell = row.getCell(left_x)) &&
     left_cell.getCellStyle.getBorderRight != Java::HSSFCellStyle::BORDER_NONE
    vborder = '|'
  end
  if !vborder && cellrange.include?(right_x) &&
     (right_cell = row.getCell(right_x)) &&
     right_cell.getCellStyle.getBorderLeft != Java::HSSFCellStyle::BORDER_NONE
    vborder = '|'
  end
  #vborder ||= ' '
  vborder
end

def convert_sheet(filename, book, i, csvgen)
  sheet = book.getSheetAt(i)
  sheetname = book.getSheetName(i)
  merged = get_merged_regions(sheet)
  rownums = sheet.getFirstRowNum..sheet.getLastRowNum
  min_firstcol = rownums.map {|y| sheet.getRow(y).getFirstCellNum }.min
  max_lastcol = rownums.map {|y| sheet.getRow(y).getLastCellNum-1 }.max
  sheet_header = []
  sheet_header << filename if $opt_prepend_filename
  sheet_header << sheetname if $opt_all_sheets
  csvgen << (sheet_header + convert_horizontal_borders(sheet, rownums.first-1, min_firstcol)) if $opt_border
  rownums.each {|y|
    record = []
    row = sheet.getRow(y)
    row_cellrange = row.getFirstCellNum...row.getLastCellNum
    record << convert_vertical_border(sheet, y, min_firstcol-1) if $opt_border
    min_firstcol.upto(row_cellrange.end-1) {|x|
      val = row_cellrange.include?(x) ? convert_cell(sheet, merged, row, x, y) : nil
      record << val
      #record << ' '
      record << convert_vertical_border(sheet, y, x) if $opt_border
    }
    csvgen << (sheet_header + record)
    csvgen << (sheet_header + convert_horizontal_borders(sheet, y, min_firstcol)) if $opt_border
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
