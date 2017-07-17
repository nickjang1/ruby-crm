require 'test_helper'

describe PurchaseOrder do
  before do
    @purchase_order_with_item_orders = create(:purchase_order_with_item_orders)
  end

  it 'must be valid' do
    @purchase_order_with_item_orders.valid?.must_equal true 
  end
  
  it 'must return a number based on its id' do
    @purchase_order_with_item_orders.id = 123
    @purchase_order_with_item_orders.number.must_equal '#00123'
  end
  

  it 'must return the rounded percentage of the number of completed item orders' do
    purchase_order = build(:purchase_order)
    item_order_1 = purchase_order.item_orders.build
    item_order_2 = purchase_order.item_orders.build
    
    item_order_1.stub :complete?, true do
      item_order_2.stub :complete?, false do
        purchase_order.percent_complete.must_equal 50
      end
    end
  end
  
  it 'must return true when complete' do
    purchase_order = build(:purchase_order)
    item_order_1 = purchase_order.item_orders.build
    item_order_2 = purchase_order.item_orders.build
    
    item_order_1.stub :complete?, true do
      item_order_2.stub :complete?, true do
        purchase_order.complete?.must_equal true
      end
    end
  end

  describe "#total_price" do
    let(:item) { create(:item) }
    let(:item_orders) {[ create(:item_order, price: 4, quantity: 2, item: item), create(:item_order, price: 5, quantity: 7, item: item)]}
    let(:po) { create(:purchase_order, item_orders: item_orders)}

    describe 'with no receivings' do
      it 'should return the sum of the order items totals' do
        po.total_price.must_equal Money.new(43 * 100)
      end
    end

    describe 'with partial receivings' do
      it 'should return the sum of the weighted average price' do
        po.item_orders.first.item_receipts << create(:item_receipt, price: 5, quantity: 2, item: item)

        po.total_price.must_equal Money.new(45 * 100)
      end
    end

    describe 'full receivings' do
    end

  end
end
