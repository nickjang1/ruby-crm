require 'test_helper'

describe InventoryVsOrdering do
  let(  :item  ){ create(:item) }
  let( :from ) { Chronic.parse('2013-01-01')}
  let( :to ) { Chronic.parse('2013-03-28')}
  let( :inventory_vs_ordering ){ InventoryVsOrdering.new(item, from..to) }

  before do
    Timecop.travel('2013-01-15') do
      create(:item_request, item: item, skip_inventory: true, count: 0)
      create(:item_request, item: item, skip_inventory: true, count: 0)
      create(:item_request, item: item, skip_inventory: true, count: 0)
      create(:item_request, item: item, skip_inventory: nil, count: 10)
      create(:item_request, item: item, skip_inventory: nil, count: 20)

      create(:item_order, item: item)
      create(:item_order, item: item)
      create(:item_order, item: item)
      create(:item_order, item: item)
      create(:item_order, item: item)
    end

    Timecop.travel('2013-02-15') do
      create(:item_request, item: item, skip_inventory: nil, count: 21)
      create(:item_request, item: item, skip_inventory: nil, count: 31)
      create(:item_order, item: item)
      create(:item_order, item: item)
    end

    Timecop.travel('2013-03-15') do
      create(:item_request, item: item, skip_inventory: nil, count: 22)
      create(:item_request, item: item, skip_inventory: nil, count: 22)
      create(:item_order, item: item)
      create(:item_order, item: item)
    end
  end
      #row[:avg_counts] = ivo.average_counts
      #row[:avg_orders] = ivo.average_orders
      #row[:last_count_at] = ivo.last_count_at
      #row[:last_order_at] = ivo.last_order_at

  describe '#average_orders' do
    it 'must return the average orders per month over the range' do
      inventory_vs_ordering.average_orders.to_i.must_equal 3

      Timecop.travel('2013-03-15') do
        create_list(:item_request, 3, item: item, skip_inventory: nil, count: 22)
        create_list(:item_order, 3, item: item)
      end

      inventory_vs_ordering.average_orders.to_i.must_equal 4
    end

    it "must not include orders outside the date range" do
      create(:item_request, item: item, skip_inventory: nil, count: 22)
      create(:item_request, item: item, skip_inventory: nil, count: 22)
      create(:item_request, item: item, skip_inventory: nil, count: 22)

      inventory_vs_ordering.average_orders.to_i.must_equal 3
    end
  end

  describe '#average_counts' do
    it 'must return the correct average' do
      inventory_vs_ordering.average_counts.to_i.must_equal 2
    end

    it 'must not include future months when calculating average' do
      Timecop.travel('2013-01-15') do
        inventory_vs_ordering.average_counts.to_i.must_equal 6
      end
    end
  end

  describe '#last_order_at' do
    it 'must return the date of the last time this item was ordered' do
      date = 1.day.ago

      Timecop.travel(date) do
        create(:item_request, item: item, skip_inventory: true)
      end

      inventory_vs_ordering.last_order_at.must_equal "03/14/2013"
    end
  end

  describe '#last_count_at' do
    it 'must return the date of the last time this item was counted' do
      Timecop.travel('2014-03-25') do
        create(:item_request, item: item, skip_inventory: nil, count: 22)
      end

      inventory_vs_ordering.last_count_at.must_equal '03/24/2014'
    end
  end
end
