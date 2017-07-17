require 'test_helper'

describe PurchaseReceipt do
  before do
    @pr = create(:purchase_receipt)  
  end

  it 'must be valid' do
    @pr.valid?.must_equal true
  end
  
  it 'must build item receipts based on it\'s purchase order item requests' do
    purchase_order = create(:purchase_order_with_item_orders)
    @pr.purchase_order = purchase_order
    purchase_order.item_orders.each do |item_order|
      @pr.item_receipts.map(&:item_order_id).must_include item_order.id
    end
  end
end
