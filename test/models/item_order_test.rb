require 'test_helper'

describe ItemOrder do
  before do
    @item_order = create(:item_order, quantity: 40)
    @item_order.item_receipts.create(quantity: 10, price: 10)
    @item_order.item_receipts.create(quantity: 10, price: 20)
  end

  it 'must return the number of items received' do
    @item_order.received.must_equal 20
  end
  
  it 'must return the percentage of items received' do
    @item_order.percent_complete.must_equal 50
  end
  
  it 'must confirm that it is not complete' do
    @item_order.complete?.must_equal false
  end

  describe '#average_price' do
    it 'must return the average of the item_receipt totals' do
      @item_order.average_price.must_equal 15
    end
  end
  
end
