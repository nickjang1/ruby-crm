require 'test_helper'

describe 'Items Integration' do

  before do
    @user = create(:user, current_property_role: Role.gm)
    sign_in @user
  end

  describe 'New Item Form' do
    let(:categories) { create_list(:category, 3) }
    let(:vendors) { create_list(:vendor, 3) }
    let(:units) { create_list(:unit, 5) }

    it 'should create a new item', js: true do
      units
      categories
      vendors

      sign_in @user
      visit new_item_path

      # checking initial state of unit selectors:
      find('select#pack-unit')['disabled'].must_equal 'disabled'
      find('select#subpack-unit')['disabled'].must_equal 'disabled'
      find('select#purchase-cost-unit option', count: 1) # purchase price selector is empty
      find('select#inventory-unit option', count: 1)     # inventoried as selector is empty

      # Selecting purchased as
      find("select#purchased-as option[value='#{ units[0].id }']").select_option
      find('select#pack-unit')['disabled'].must_equal nil

      assert page.has_css?('select#purchase-cost-unit option', count: 2)
      assert page.has_css?('select#inventory-unit option', count: 2)

      # Selecting pack unit
      find("select#pack-unit option[value='#{ units[1].id }']").select_option
      find('select#subpack-unit')['disabled'].must_equal nil

      assert page.has_css?('select#purchase-cost-unit option', count: 3)
      assert page.has_css?('select#inventory-unit option', count: 3)

      # Selecting sub-pack unit
      find("select#subpack-unit option[value='#{ units[2].id }']").select_option

      assert page.has_css?('select#purchase-cost-unit option', count: 4)
      assert page.has_css?('select#inventory-unit option', count: 4)

      # should have one vendor form:
      assert page.has_css?('#vendors .vendor', count: 1)
      find('#add_vendor').click() # adding one more vendor
      assert page.has_css?('#vendors .vendor', count: 2), "should have 2 vendors after adding"

      # trying to remove last vendor:
      page.execute_script('$("#vendors .vendor:last-child .remove_btn").click()')
      find('a', text: "YES I'm sure!").click() # confirming
      assert page.has_css?('#vendors .vendor', count: 1), "should have 1 vendor after removing"

      # filling up required fields:
      fill_in 'item_name', with: "Item XXX"
      find('select#purchase-cost-unit option:last-child').select_option
      find('select#inventory-unit option:last-child').select_option
      find('select#item_category_ids option:last-child').select_option
      find('select#item_vendor_items_attributes_0_vendor_id option:last-child').select_option
      click_button 'Create Item'
      sleep 1
      # screenshot_and_open_image
      page.text.must_include "Item XXX"
    end

    it "could select multiple items in listing page", js: true do
      sign_in @user
      @items = create_list(:item, 5)
      visit items_path

      # list all items
      find(".breadcrumb li", text: 'Items')
      all('table.searchable-table tbody tr').count.must_equal @items.count
      @items.each do |item|
        find('td', text: item.number)
      end

      # select all items
      find('input#customcheckbox-item-select-all', visible: false).trigger(:click)
      all('table.searchable-table tbody tr').each do |tr|
        tr['class'].must_include 'success'
      end
      # deselect all items
      find('input#customcheckbox-item-select-all', visible: false).trigger(:click)
      # select some items
      @items.each_with_index do |item, index|
        find("input#customcheckbox-item-#{item.id}", visible: false).trigger(:click) if index % 2 == 0
      end
      find('input#customcheckbox-item-select-all', visible: false)['checked'].must_equal false
    end
  end

  describe 'open requests/orders count' do
    it 'should not display badge with counts if counts == 0' do
      visit items_path
      assert page.has_no_css?('table tr td .label-danger')
    end

    it 'should display badge on item listing if at least one PR with this item still not closed', js: true do
      i = create(:item)
      create(:purchase_request, item_requests: [ create(:item_request, item: i) ])
      visit items_path
      assert page.has_css?('table tr td .label-danger')
    end

    it 'should display badge on item listing if at least one PO with this item still not closed', js: true do
      i = create(:item)
      create(:purchase_order, item_orders: [ create(:item_order, item: i) ], state: :open)
      visit items_path
      assert page.has_css?('table tr td .label-danger')
    end

    it 'should display widget when clicking on badge', js: true do
      i = create(:item)
      i.vendors << create(:vendor)

      #<=== creating PO:
      pr1 = create(:purchase_request, state: 'ordered')
      ir1 = create(:item_request, purchase_request: pr1, item: i)
      pr1.create_orders_on_approval!(@user, Property.current)
      # ==> END

      #<=== creating PO:
      pr1 = create(:purchase_request, state: 'ordered')
      ir1 = create(:item_request, purchase_request: pr1, item: i)
      pr1.create_orders_on_approval!(@user, Property.current)
      PurchaseOrder.last.update_attributes(state: 'closed') # should be ignored
      # ==> END

      create(:purchase_request, item_requests: [ create(:item_request, item: i) ], state: 'ordered') # should be ignored
      create(:purchase_request, item_requests: [ create(:item_request, item: i) ], state: 'completed')
      create(:purchase_request, item_requests: [ create(:item_request, item: i) ], state: 'completed')

      visit items_path
      # save_and_open_page
      find('table tr td .label-danger').text.must_include "2 | 1"
      find('table tr td .label-danger').trigger(:click)
      page.text.must_include "Open Requests & Orders"
      assert page.has_css?('table tr td .media-list .media', count: 3)
    end
  end

  describe "item editing" do

    it 'should not allow to remove last vendor', js: true do
      i = create(:item)
      visit edit_item_path(i)
      sleep 1
      find('#vendors .vendor:first-child').hover
      assert page.has_no_css?('#vendors .vendor:first-child .activate-inactivate', visible: true),
        "there should be no delete link if vendor is last"
      find('#add_vendor').click()
      find('#vendors .vendor:nth-child(1)').hover
      assert page.has_css?('#vendors .vendor:nth-child(1) .activate-inactivate', visible: true)
      find('#vendors .vendor:nth-child(2)').hover
      assert page.has_css?('#vendors .vendor:nth-child(2) .activate-inactivate', visible: true)
    end
  end
end
