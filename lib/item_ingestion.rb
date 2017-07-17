
# Handles ingestion of items from spreadsheets
module ItemIngestion
  include ActionView::Helpers::NumberHelper
  # Denotes a situation where the spreadsheet could not be processed
  class SpreadsheetError < StandardError; end

  FIRST_ROW = 4

  MIMETYPE_HANDLERS = {
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => Roo::Excelx}
      # 'application/vnd.ms-excel' => Roo::Excel,
      # 'application/excel' => Roo::Excel}

  COLUMNS = {
      name:               'A',
      manufacturer:       'B',
      categories:         'C',
      locations:          'D',
      lists:              'E',
      vendor_name:        'F',
      price:              'G',
      sku:                'H',
      taxable:            'I',
      asset:              'J',
      par:                'K',
      purchase_unit:      'L',
      pack_size:          'M',
      pack_unit:          'N',
      subpack_size:       'O',
      subpack_unit:       'P',
      inventory_unit:     'Q',
      price_unit:         'R',
      notes:              'S'
  }

  # Returns a roo spreadsheet object to handle the given file
  def self.spreadsheet_for(file)
    mime_types = MIME::Types.type_for(file.original_filename).map(&:content_type)
    handlers = mime_types.map{|mt| MIMETYPE_HANDLERS[mt]}.compact

    raise SpreadsheetError if handlers.empty?

    spreadsheet = handlers.first.new(file.path, nil, :ignore)

    spreadsheet.default_sheet = spreadsheet.sheets.first

    return spreadsheet
  end

  def self.read_excel(current_property, file)
    begin
      ss = spreadsheet_for(file)
    rescue SpreadsheetError => e
      return false
    end

    items = []

    FIRST_ROW.upto ss.last_row do |row|
      # Vendor
      vendor = Vendor.where(name: ss.cell(row, COLUMNS[:vendor_name]).to_s).first_or_create

      # Manufacturer
      brand = Brand.where(name: ss.cell(row, COLUMNS[:manufacturer]).to_s).first_or_create

      # Units
      unit = Unit.where(name: ss.cell(row, COLUMNS[:purchase_unit]).to_s).first_or_create
      subpack = Unit.where(name: ss.cell(row, COLUMNS[:subpack_unit]).to_s).first_or_create
      pack = Unit.where(name: ss.cell(row, COLUMNS[:pack_unit]).to_s).first_or_create
      price_unit = Unit.where(name: ss.cell(row, COLUMNS[:price_unit]).to_s).first_or_create
      inventory_unit = Unit.where(name: ss.cell(row, COLUMNS[:inventory_unit]).to_s).first_or_create
      units = Unit.where(id: [unit.id, inventory_unit.id, subpack.id, pack.id])

      # Tags
      category_ids = []
      (ss.cell(row, COLUMNS[:categories]).to_s || '').split(/\s*,\s*/).each  do |category_name|
        tags = extract_tags(ss.cell(row, COLUMNS[:categories]).to_s, :categories, current_property)
        category_ids = tags.map(&:id)
      end

      location_ids = []
      (ss.cell(row, COLUMNS[:locations]).to_s || '').split(/\s*,\s*/).each do |locaiton_name|
        tags = extract_tags(ss.cell(row, COLUMNS[:locations]).to_s, :locations, current_property)
        location_ids = tags.map(&:id)
      end

      list_ids = []
      (ss.cell(row, COLUMNS[:lists]).to_s || '').split(/\s*,\s*/).each do |list_name|
        tags = extract_tags(ss.cell(row, COLUMNS[:lists]).to_s, :lists, current_property)
        list_ids = tags.map(&:id)
      end

      item = current_property.items.new(
          name: ss.cell(row, COLUMNS[:name]).to_s,
          brand_id: brand.id,
          par_level: ss.cell(row, COLUMNS[:par]).blank? ? nil : ss.cell(row, COLUMNS[:par]).to_s.to_f,
          is_taxable: ss.cell(row, COLUMNS[:taxable]).to_s.downcase == 'yes' ? true: false,
          is_asset: ss.cell(row, COLUMNS[:asset]).to_s.downcase == 'yes' ? true: false,
          category_ids: category_ids,
          location_ids: location_ids,
          list_ids: list_ids,
          vendor_items_attributes: {
              0 => {
                  vendor_id: vendor.try(:id),
                  price: ss.cell(row, COLUMNS[:price]).blank? ? nil : ss.cell(row, COLUMNS[:price]).to_s.to_f,
                  sku: ss.celltype(row, COLUMNS[:sku]) == :string ? ss.cell(row, COLUMNS[:sku]) : ss.excelx_value(row, COLUMNS[:sku]),
                  preferred: true
              }
          },
          unit_id: unit.try(:id),
          pack_unit_id: pack.try(:id),
          pack_size: ss.cell(row, COLUMNS[:pack_size]).blank? ? nil : ss.cell(row, COLUMNS[:pack_size]).to_s.to_f,
          subpack_unit_id: subpack.try(:id),
          subpack_size: ss.cell(row, COLUMNS[:subpack_size]).blank? ? nil : ss.cell(row, COLUMNS[:subpack_size]).to_s.to_f,
          purchase_cost: ss.cell(row, COLUMNS[:price]).blank? ? nil: ('%.2f' % ss.cell(row, COLUMNS[:price]).to_s.to_f),
          price_unit_id: price_unit.id,
          inventory_unit_id: inventory_unit.id,
          description: ss.cell(row, COLUMNS[:notes]).to_s
      )

      return false unless item.save

      items << item.id
    end
    items
  end

  def self.extract_tags(tags_csv, type, current_property)
    tags = (tags_csv || '').split(/\s*,\s*/).map(&:strip)
    tag_class = type.to_s.capitalize.singularize.constantize
    tags.map do |tag|
      _tag = tag_class.where(name: tag).first

      if _tag.nil?
        _tag = tag_class.new(name: tag, property_id: current_property.id)
        _tag.update_attribute(:siblings_position, :last)
      end
      _tag
    end
  end

  # Removes the decimal part from the given number string
  #
  # @param [String, Fixnum, Float] number The product number to be cleaned up
  # @return [String] The given +number+, sans decimal suffix
  def self.format_item_number(number)
    case number.class.to_s
      when 'String' then number
      when 'Fixnum' then number.to_s
      when 'Float' then number.to_i.to_s
    end
  end
end
