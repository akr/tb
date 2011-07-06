#!/usr/bin/jruby

# sample/poi-xls2csv.rb - XLS to CSV convert using Apache POI with JRuby.
#
# Copyright (C) 2011 Tanaka Akira  <akr@fsij.org>
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
$opt_type = false

op = OptionParser.new
op.def_option('-h', 'show help message') { puts op; exit true }
op.def_option('-a', 'convert all sheets (sheet name is prepended to all rows)') { $opt_all_sheets = true }
op.def_option('-f', 'prepend filename for all rows') { $opt_prepend_filename = true }
op.def_option('--mergecells=mode', '"fill" or "topleft"') {|v| $opt_mergecells = v }
op.def_option('--border', 'extract borders') { $opt_border = true }
op.def_option('-t', '--type', 'add type suffix') { $opt_type = true }
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
  if !cell
    return nil
  end
  style = cell.getCellStyle
  case cell.getCellType
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_NUMERIC
    if Java::HSSFDateUtil.isCellDateFormatted(cell) ||
       ExcelDateStylesHash[style.getDataFormat]
      d = cell.getDateCellValue
      val = "%d-%02d-%02d %02d:%02d:%02d" % [
	d.getYear+1900, d.getMonth+1, d.getDate, d.getHours, d.getMinutes, d.getSeconds
      ]
      val = val + ":date" if $opt_type
    else
      val = cell.getNumericCellValue
      val = val.to_s + ":numeric" if $opt_type
    end
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_STRING
    str = cell.getRichStringCellValue.getString
    val = str
    val = val + ":string" if $opt_type
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_FORMULA
    val = cell.getCellFormula
    val = val.to_s + ":formula" if $opt_type
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_BLANK
    val = nil
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_BOOLEAN
    val = cell.getBooleanCellValue
    val = val.to_s + ":boolean" if $opt_type
  when Java::OrgApachePoiHssfUsermodel::HSSFCell::CELL_TYPE_ERROR
    val = "\#ERR#{cell.getErrorCellValue}"
    val = val + ":error" if $opt_type
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
    if $opt_type
      val = val.to_s + ":mergedarea(#{x2-x1+1}x#{y2-y1+1},#{x1+1},#{y1+1})"
    end
  else
    val = convert_single_cell(row.getCell(x))
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

def bordertype(border)
  case border
  when Java::HSSFCellStyle::BORDER_NONE then "border(none)"
  when Java::HSSFCellStyle::BORDER_THIN then "border(thin)"
  when Java::HSSFCellStyle::BORDER_MEDIUM then "border(medium)"
  when Java::HSSFCellStyle::BORDER_DASHED then "border(dashed)"
  when Java::HSSFCellStyle::BORDER_DOTTED then "border(dotted)"
  when Java::HSSFCellStyle::BORDER_THICK then "border(thick)"
  when Java::HSSFCellStyle::BORDER_DOUBLE then "border(double)"
  when Java::HSSFCellStyle::BORDER_HAIR then "border(hair)"
  when Java::HSSFCellStyle::BORDER_MEDIUM_DASHED then "border(medium_dashed)"
  when Java::HSSFCellStyle::BORDER_DASH_DOT then "border(dash_dot)"
  when Java::HSSFCellStyle::BORDER_MEDIUM_DASH_DOT then "border(medium_dash_dot)"
  when Java::HSSFCellStyle::BORDER_DASH_DOT_DOT then "border(dash_dot_dot)"
  when Java::HSSFCellStyle::BORDER_MEDIUM_DASH_DOT_DOT then "border(medium_dash_dot_dot)"
  when Java::HSSFCellStyle::BORDER_SLANTED_DASH_DOT then "border(slanted_dash_dot)"
  else
    "border(#{border})"
  end
end

def convert_horizontal_borders(sheet, merged, upper_y, min_firstcol)
  rownums = sheet.getFirstRowNum..sheet.getLastRowNum
  lower_y = upper_y+1
  min = 0
  max = 0
  if rownums.include? upper_y and
     upper_row = sheet.getRow(upper_y) and
     (upper_cellrange = upper_row.getFirstCellNum...upper_row.getLastCellNum) and
     upper_cellrange.begin != -1 and
     upper_cellrange.end != -1
    if max < (upper_cellrange.end-min_firstcol)*2
      max = (upper_cellrange.end-min_firstcol)*2
    end
  end
  if rownums.include? lower_y and
     lower_row = sheet.getRow(lower_y) and
     (lower_cellrange = lower_row.getFirstCellNum...lower_row.getLastCellNum) and
     lower_cellrange.begin != -1 and
     lower_cellrange.end != -1
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
	if !merged[[left_x, upper_y]] || !merged[[right_x, upper_y]] ||
	   merged[[left_x, upper_y]] != merged[[right_x, upper_y]]
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
	end
	if !merged[[left_x, upper_y]] || !merged[[left_x, lower_y]] ||
	   merged[[left_x, upper_y]] != merged[[left_x, lower_y]]
	  if !left_line && upper_cellrange.include?(left_x) &&
	     (upperleft_cell = upper_row.getCell(left_x)) &&
	     upperleft_cell.getCellStyle.getBorderBottom != Java::HSSFCellStyle::BORDER_NONE
	    left_line = true
	  end
	end
	if !merged[[right_x, upper_y]] || !merged[[right_x, lower_y]] ||
	   merged[[right_x, upper_y]] != merged[[right_x, lower_y]]
	  if !right_line && upper_cellrange.include?(right_x) &&
	     (upperright_cell = upper_row.getCell(right_x)) &&
	     upperright_cell.getCellStyle.getBorderBottom != Java::HSSFCellStyle::BORDER_NONE
	    right_line = true
	  end
	end
      end
      if lower_row
	if !merged[[left_x, lower_y]] || !merged[[right_x, lower_y]] ||
	   merged[[left_x, lower_y]] != merged[[right_x, lower_y]]
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
	end
	if !merged[[left_x, upper_y]] || !merged[[left_x, lower_y]] ||
	   merged[[left_x, upper_y]] != merged[[left_x, lower_y]]
	  if !left_line && lower_cellrange.include?(left_x) &&
	     (lowerleft_cell = lower_row.getCell(left_x)) &&
	     lowerleft_cell.getCellStyle.getBorderTop != Java::HSSFCellStyle::BORDER_NONE
	    left_line = true
	  end
	end
	if !merged[[right_x, upper_y]] || !merged[[right_x, lower_y]] ||
	   merged[[right_x, upper_y]] != merged[[right_x, lower_y]]
	  if !right_line && lower_cellrange.include?(right_x) &&
	     (lowerright_cell = lower_row.getCell(right_x)) &&
	     lowerright_cell.getCellStyle.getBorderTop != Java::HSSFCellStyle::BORDER_NONE
	    right_line = true
	  end
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
      joint = joint + ":joint" if joint && $opt_type
      ary << joint
    else
      # cell
      hborder = nil
      cell_x = min_firstcol + i / 2
      if !merged[[cell_x, upper_y]] || !merged[[cell_x, lower_y]] ||
	 merged[[cell_x, upper_y]] != merged[[cell_x, lower_y]]
	if !hborder && upper_row && upper_cellrange.include?(cell_x) &&
	   (upper_cell = upper_row.getCell(cell_x)) &&
	   upper_cell.getCellStyle.getBorderBottom != Java::HSSFCellStyle::BORDER_NONE
	  hborder = '-'
	  hborder = hborder + ":#{bordertype(upper_cell.getCellStyle.getBorderBottom)}" if $opt_type
	end
	if !hborder && lower_row && lower_cellrange.include?(cell_x) &&
	   (lower_cell = lower_row.getCell(cell_x)) &&
	   lower_cell.getCellStyle.getBorderTop != Java::HSSFCellStyle::BORDER_NONE
	  hborder = '-'
	  hborder = hborder + ":#{bordertype(lower_cell.getCellStyle.getBorderTop)}" if $opt_type
	end
      end
      #hborder ||= ' '
      ary << hborder
    end
  }
  ary
end

def convert_vertical_border(sheet, merged, cell_y, left_x)
  right_x = left_x+1
  row = sheet.getRow(cell_y)
  return nil if !row
  cellrange = row.getFirstCellNum...row.getLastCellNum
  return nil if cellrange.begin == -1 || cellrange.end == -1
  vborder = nil
  if !merged[[left_x, cell_y]] || !merged[[right_x, cell_y]] ||
     merged[[left_x, cell_y]] != merged[[right_x, cell_y]]
    if !vborder && cellrange.include?(left_x) &&
       (left_cell = row.getCell(left_x)) &&
       left_cell.getCellStyle.getBorderRight != Java::HSSFCellStyle::BORDER_NONE
      vborder = '|'
      vborder = vborder + ":#{bordertype(left_cell.getCellStyle.getBorderRight)}" if $opt_type
    end
    if !vborder && cellrange.include?(right_x) &&
       (right_cell = row.getCell(right_x)) &&
       right_cell.getCellStyle.getBorderLeft != Java::HSSFCellStyle::BORDER_NONE
      vborder = '|'
      vborder = vborder + ":#{bordertype(right_cell.getCellStyle.getBorderLeft)}" if $opt_type
    end
  end
  #vborder ||= ' '
  vborder
end

def convert_sheet(filename, book, i, csvgen)
  sheet = book.getSheetAt(i)
  sheetname = book.getSheetName(i)
  merged = get_merged_regions(sheet)
  rownums = 0..sheet.getLastRowNum
  min_firstcol = 0
  max_lastcol = rownums.map {|y|
    if !(row = sheet.getRow(y))
      nil
    elsif (n = row.getLastCellNum) == -1
      nil
    else
      n-1
    end
  }.compact.max
  sheet_header = []
  if $opt_prepend_filename
    filename += ":filename" if $opt_type
    sheet_header << filename
  end
  if $opt_all_sheets
    sheetname += ":sheetname" if $opt_type
    sheet_header << sheetname
  end
  csvgen << (sheet_header + convert_horizontal_borders(sheet, merged, rownums.first-1, min_firstcol)) if $opt_border
  rownums.each {|y|
    record = []
    row = sheet.getRow(y)
    if row
      row_cellrange = row.getFirstCellNum...row.getLastCellNum
      if row_cellrange.begin != -1 && row_cellrange.end != -1
        record << convert_vertical_border(sheet, merged, y, min_firstcol-1) if $opt_border
        min_firstcol.upto(row_cellrange.end-1) {|x|
          val = row_cellrange.include?(x) ? convert_cell(sheet, merged, row, x, y) : nil
          record << val
          #record << ' '
          record << convert_vertical_border(sheet, merged, y, x) if $opt_border
        }
      end
    end
    csvgen << (sheet_header + record)
    csvgen << (sheet_header + convert_horizontal_borders(sheet, merged, y, min_firstcol)) if $opt_border
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
