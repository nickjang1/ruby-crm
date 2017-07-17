
require "test_helper"

describe Property do
  describe '.current' do
    it 'should return the current property if there is on' do
      Property.current.must_equal Property.first
    end
  end

  describe '#switch!' do
    it 'should switch to this property' do
      Property.current.must_equal Property.first
      other_property = create(:property)

      other_property.switch!

      Property.current.must_equal other_property
    end
  end

  describe '#run_block' do
    it 'should .. switch to this property execute a block of code then switch back' do
      other_property = create(:property)
      create_list(:item, 5)

      item_count = Item.count

      other_property.run_block do
        create_list(:item, 2)
      end

      item_count.must_equal Item.count

      other_property.switch!
      Item.count.must_equal 2
    end
  end
end
