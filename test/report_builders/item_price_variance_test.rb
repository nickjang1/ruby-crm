require 'test_helper'

describe ItemPriceVariance do
  let(:vendor1) { create(:vendor) }
  let(  :item  ){ create(:item) }
  let( :from ) { Date.today.beginning_of_month }
  let( :to ) { Date.today.end_of_month }
  let(  :item_price_variance  ){ ItemPriceVariance.new(item, from..to) }

  before do
    vendor2 = create(:vendor)
    po2= create(:purchase_order, vendor: vendor2)
    po1= create(:purchase_order, vendor: vendor1)
    po3= create(:purchase_order, vendor: vendor1)
    item_order1= create(:item_order, item: item, purchase_order: po2, quantity: 10, price:10)
    item_order2= create(:item_order, item: item, purchase_order: po1, quantity: 5, price:20)
    item_order3= create(:item_order, item: item, purchase_order: po3, quantity: 15, price:15)
    create(:item_receipt, price: 20, quantity: 10, item: item, item_order: item_order1)
    create(:item_receipt, price: 40, quantity: 5, item: item, item_order: item_order2)
    create(:item_receipt, price: 10, quantity: 5, item: item, item_order: item_order2)
    create(:item_receipt, price: 15, quantity: 15, item: item, item_order: item_order3)
  end

  describe '#num_orders' do
    it 'must return the correct number of orders' do
      item_price_variance.num_orders.must_equal 3
    end

    it "must not count orders that have no receivings" do
      po4= create(:purchase_order, vendor: vendor1)
      create(:item_order, item: item, purchase_order: po4, quantity: 15, price:15)

      item_price_variance.num_orders.must_equal 3
    end
  end

  describe '#average_price' do
    it 'must return the correct average' do
      item_price_variance.average_price.must_equal "21.25"
    end
  end

  describe '#average_variance' do
    it 'Calculates with absolute value of the difference between the order price and the received price = [Total Absolute Difference / Total # of Receivings with difference between ordered and received prices])' do
      item_price_variance.average_variance.must_equal "13.33"
    end
  end

  describe '#increase' do
    it 'calculates the % increase when the item_receipt total is greater than the item_order total' do
      item_price_variance.increase.must_equal '100'
    end
  end
end
