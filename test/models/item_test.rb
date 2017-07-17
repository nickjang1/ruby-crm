require 'test_helper'

describe Item do
  before do
    @item = create(:item_with_vendor_item)  
  end

  it 'must be valid' do
    @item.valid?.must_equal true
  end
  
  it 'must have countable units' do
    tags = create_list :tag, 3
    @item.tags << tags
    @item.has_countable_units?.must_equal false
    
    tags.first.update_attribute(:unboxed_countable, true)
    @item.has_countable_units?.must_equal true
  end

  it 'doesn\'t share item number between hotels' do
    Item.unscoped.destroy_all
    property1 = create(:property)
    property2 = create(:property)
    Property.current_id = property1.id
    p1_items = create_list(:item_with_vendor_item, 10, property: property1)
    Property.current_id = property2.id
    p2_items = create_list(:item_with_vendor_item, 5, property: property2)
    p1_items.last.number.must_equal '10009'
    p2_items.last.number.must_equal '10004'
  end
end
