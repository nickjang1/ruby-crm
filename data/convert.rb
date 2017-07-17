#!/usr/bin/env ruby
require 'spreadsheet'
require 'csv'

# Processes the spreadsheet given as $1 and outputs a fixed version to
# the same basename in /tmp.  Ignores hidden rows.

COLUMNS = [
  :number,
  :name,
  :brand,
  :categories,
  :locations,
  :lists,
  :vendor_name,
  :price,
  :taxable,
  :par,
  :purchase_unit,
  :pack_quantity,
  :pack_unit,
  :subpack_quantity,
  :subpack_unit,
  :inventory_unit,
  :notes,
]

# Little wrapper to make get and set methods a little prettier
class Row < SimpleDelegator
  def col(label)
    self[label_index(label)]
  end

  def set(label, value)
    self[label_index(label)] =  value
  end

  protected

  def label_index(label)
    unless COLUMNS.include?(label)
      raise ArgumentError, "#{label} is not a valid column label"
    end

    COLUMNS.index(label)
  end
end

class SpreadsheetConverter
  # zero based
  FIRST_DATA_ROW = 3

  attr_reader :ss, :new_book

  def initialize(filename)
    @book = Spreadsheet.open(filename)
    @ss = @book.worksheet(0)

    @new_book = Spreadsheet::Workbook.new
    @new_book.add_worksheet(Spreadsheet::Worksheet.new)

    @new_ss = new_book.worksheet(0)

    @copied_row_count = 0
  end

  def convert
    @copied_row_count = 0
    copy_header_rows
    copy_body_rows
  end

  protected

  def last_header_row
    FIRST_DATA_ROW - 1
  end

  def copy_header_rows
    0.upto(last_header_row) { |i| @new_ss.insert_row(i, ss.row(i).to_a) }
    @copied_row_count = FIRST_DATA_ROW
  end

  def copy_body_rows
    FIRST_DATA_ROW.upto ss.rows.length do |row_index|
      row = Row.new(ss.row(row_index))

      unless row.hidden
        transpose_row(row)

        @new_ss.insert_row(@copied_row_count, row)
        @copied_row_count += 1
      end
    end
  end

  # @note Works through side effects on the given +row+
  def transpose_row(row)
    pack_unit = row.col(:purchase_unit)

    if row.col(:subpack_unit)
      subpack_unit = row.col(:pack_unit)
      individual_unit = row.col(:subpack_unit)
    else
      individual_unit = row.col(:pack_unit)
      subpack_unit = nil
    end

    subpack_quantity = row.col(:subpack_quantity)
    if (subpack_unit || "").strip == 'dozen'
      subpack_quantity = 12 
    end

    row.set(:pack_unit, pack_unit)
    row.set(:subpack_unit, subpack_unit)
    row.set(:subpack_quantity, subpack_quantity)
    row.set(:inventory_unit, individual_unit)
  end
end

if __FILE__ == $0
  filename = ARGV.first

  converter = SpreadsheetConverter.new(filename)
  converter.convert
  converter.new_book.write('/tmp/' + File.basename(filename))
end
