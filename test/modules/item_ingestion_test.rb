require "test_helper"

describe 'Importing Items with XLSX' do
  
  let (:property) { create(:property) }
  
  it "imports items from xlsx file" do
    Property.current_id = property.id
    
    file = File.open(Rails.root.join('test/support/data/items1.xlsx'))
    filename = File.basename(file.path)
    uploaded_file = ActionDispatch::Http::UploadedFile.new(
      tempfile: file,
      filename: filename,
      head: %Q{Content-Disposition: form-data; name="template"; filename="#{filename}"},
      content_type: MIME::Types.type_for(filename).first
    )
    
    ItemIngestion.read_excel(property, uploaded_file)
    
    Item.count.must_equal 3
    Brand.count.must_equal 2
    Category.count.must_equal 1
    Location.count.must_equal 1
    VendorItem.count.must_equal 3
    Unit.count.must_equal 3
    
    first = Item.find_by_name('Mints Tic Tac Freshmint')
    first.brand.name.must_equal 'Tic Tac'
    first.categories.count.must_equal 1
    first.categories.first.name.must_equal 'Food & Beverage'
    first.locations.count.must_equal 1
    first.locations.first.name.must_equal 'Suite Shop'
    first.vendor_items.count.must_equal 1
    first.vendors.first.name.must_equal 'Vistar'
    first.vendor_items.first.price.must_equal 317.39
    first.vendor_items.first.sku.must_equal 'FEU00771'
    first.is_taxable.must_equal true
    first.is_asset.must_equal false
    first.pack_size.must_equal 24.0
    first.pack_unit.name.must_equal 'PACK'
    first.subpack_size.must_equal 12.0
    first.subpack_unit.name.must_equal 'EACH'
    first.par_level.must_equal nil

    second = Item.find_by_name('Mints Tic Tac Orange')
    second.brand.name.must_equal 'Tic Tac'
    second.categories.count.must_equal 1
    second.categories.first.name.must_equal 'Food & Beverage'
    second.locations.count.must_equal 1
    second.locations.first.name.must_equal 'Suite Shop'
    second.vendor_items.count.must_equal 1
    second.vendors.first.name.must_equal 'Vistar'
    second.vendor_items.first.price.must_equal 320.00
    second.vendor_items.first.sku.must_equal '33333333'
    second.par_level.must_equal 333.0
    second.is_taxable.must_equal false
    second.is_asset.must_equal true
    second.pack_size.must_equal 20.0
    second.pack_unit.name.must_equal 'PACK'
    second.subpack_size.must_equal 10.0
    second.subpack_unit.name.must_equal 'EACH'

    third = Item.find_by_name('Milk Choco w/Caramel Bar')
    third.brand.name.must_equal 'Ghirardelli Chocolate Co'
    third.categories.count.must_equal 1
    third.categories.first.name.must_equal 'Food & Beverage'
    third.locations.count.must_equal 1
    third.locations.first.name.must_equal 'Suite Shop'
    third.vendor_items.count.must_equal 1
    third.vendors.first.name.must_equal 'Vistar'
    third.vendor_items.first.price.must_equal Money.new(nil)
    third.vendor_items.first.sku.must_equal 'MSD60764'
    third.par_level.must_equal nil
    third.is_taxable.must_equal true
    third.is_asset.must_equal true
    third.pack_size.must_equal 12.0
    third.pack_unit.name.must_equal 'EACH'
    third.subpack_size.must_equal nil
    third.subpack_unit.must_equal nil
  end
  
end
