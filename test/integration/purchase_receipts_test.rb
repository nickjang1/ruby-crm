require 'test_helper'

describe 'Purchase Receipts Integration' do

  describe 'common tests' do
    before do
      sign_in create(:user)
      item = create(:item)
      vendor = create(:vendor)
      @po = create(:purchase_order, vendor: vendor)
      
      vendor.vendor_items << create(:vendor_item, item: item)
      @po.item_orders << create(:item_order, item: item)
    end

    it 'generates item receipts based on it\'s purchase_order\'s item orders' do
      visit new_purchase_receipt_path({purchase_order_id: @po.id})
      @po.item_orders.map(&:item).each do |item|
        page.text.must_include item.name
      end
    end
    
    it 'marks it\'s purchase order as closed if it is complete' do
      visit new_purchase_receipt_path({purchase_order_id: @po.id})
      click_button "Receive"
      flash_messages.first.must_include "Purchase Order #{@po.number} was successfully received."
      page.text.wont_include @po.number
    end

    it 'marks it\'s purchase order as closed if it is complete' do
      visit new_purchase_receipt_path({purchase_order_id: @po.id})
      click_button "Receive"
      flash_messages.first.must_include "Purchase Order #{@po.number} was successfully received."
      page.text.wont_include @po.number
    end
  end

  describe 'JavaScript calculations' do
    let(:vendor){ create(:vendor) }
    let(:po){ create(:purchase_order, vendor: vendor) }
    
    before do
      sign_in create(:user)
      items = create_list(:item, 3)
      
      vendor.vendor_items << create(:vendor_item, item: items[0])
      vendor.vendor_items << create(:vendor_item, item: items[1])
      vendor.vendor_items << create(:vendor_item, item: items[2])

      po.item_orders << create(:item_order, quantity: 2, price: 10.5, item: items[0])
      po.item_orders << create(:item_order, quantity: 2, price: 12, item: items[1])
      po.item_orders << create(:item_order, quantity: 4, price: 125.00, item: items[2])
    end

    it 'should calculates totals properly', js: true do
      visit new_purchase_receipt_path(purchase_order_id: po.id)

      # checking initial values:
      assert page.has_css?('table tbody tr.item', count: 3)
      find_field('purchase_receipt_item_receipts_attributes_0_quantity').value.must_equal '4.0'
      find_field('purchase_receipt_item_receipts_attributes_1_quantity').value.must_equal '2.0'
      find_field('purchase_receipt_item_receipts_attributes_2_quantity').value.must_equal '2.0'
      find_field('purchase_receipt_item_receipts_attributes_0_price').value.must_equal '125.0'
      find_field('purchase_receipt_item_receipts_attributes_1_price').value.must_equal '12.0'
      find_field('purchase_receipt_item_receipts_attributes_2_price').value.must_equal '10.5'

      find('#total-price-value').text.must_equal '545.00'
      find('#total-with-freight-value').text.must_equal '545.00'

      find('table tbody tr.item:nth-child(1) td:last-child .total-item-cost').text.must_equal '500.00'
      find('table tbody tr.item:nth-child(2) td:last-child .total-item-cost').text.must_equal '24.00'
      find('table tbody tr.item:nth-child(3) td:last-child .total-item-cost').text.must_equal '21.00'

      #changing values:
      fill_in('purchase_receipt_item_receipts_attributes_0_quantity', with: '2')
      find('table tbody tr.item:nth-child(1) td:last-child .total-item-cost').text.must_equal '250.00'
      find('#total-price-value').text.must_equal '295.00'
      find('#total-with-freight-value').text.must_equal '295.00'
      fill_in('purchase_receipt_item_receipts_attributes_2_quantity', with: '3.5')
      find('table tbody tr.item:nth-child(3) td:last-child .total-item-cost').text.must_equal '36.75'
      find('#total-price-value', text: '310.75')
      find('#total-with-freight-value').text.must_equal '310.75'

      fill_in('inputFreight', with: '25.25')
      find('#total-price-value').text.must_equal '310.75'
      find('#total-with-freight-value').text.must_equal '336.00'

      # trying to break:
      fill_in('inputFreight', with: 'adsfdg')
      find('#total-price-value').text.must_equal '310.75'
      find('#total-with-freight-value').text.must_equal '310.75'

      fill_in('purchase_receipt_item_receipts_attributes_0_quantity', with: 'fddsgffgd')
      find('table tbody tr.item:nth-child(1) td:last-child .total-item-cost').text.must_equal '0.00'
      find('#total-price-value').text.must_equal '60.75'
      find('#total-with-freight-value').text.must_equal '60.75'

      find('button[type="submit"]').click()
    end
  end
end
