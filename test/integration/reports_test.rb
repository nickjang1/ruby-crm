require 'test_helper'

describe 'Reports Integration' do
  let(:end_of_month){ Time.now.end_of_month - 2.days }

  before do
    @user = create(:user)
    sign_in @user
  end

  it 'should favorite reports', js: true do
    skip "WILL FIX AFTER FINISHING PM"
    Report::ALL_KINDS.each { |report_fields|  Report.create(report_fields) }
    visit reports_path

    assert page.has_css?('.widget.panel', count: 11) # checking reports count
    find('#favorite_reports_count.hidden', visible: false) # favorite counter should be hidden
    find('.shuffle-item:nth-child(1) .widget a.favorite').trigger(:click) # clicking favicon on first report
    find('#favorite_reports_count', text: "1") # favorite counter should appear and show "1"
    find('.shuffle-item:nth-child(2) .widget a.favorite').trigger(:click) # clicking favicon on second report
    find('#favorite_reports_count', text: "2") # favorite counter should show "2"

    visit reports_path
    find('#favorite_reports_count', text: "2")
    assert page.has_css?('.widget.panel.favorite', count: 2)
    find('.shuffle-item:nth-child(1) .widget a.favorite').trigger(:click)
    find('#favorite_reports_count', text: "1")
  end

  it "shows correct data for items_consumption report", js:true do
    skip "WILL FIX AFTER FINISHING PM"
    Timecop.travel(end_of_month) do
      Report.create(permalink: 'items_consumption', name: 'Items Consumption', groups: 'spending')

      category1 = create(:category)
      category2 = create(:category)

      vendor = create(:vendor)
      item1  = create(:item, name: 'Lovely Widget', vendors: [ vendor ], categories: [category1])
      item2  = create(:item, name: 'Washing Pie 4', vendors: [ vendor ], categories: [category2])
      # don't change items names since it could break order in which items are rendered
      pr  = create(:purchase_request)
      ir1 = create(:item_request, purchase_request: pr, item: item1)
      ir2 = create(:item_request, purchase_request: pr, item: item2)
      po  = create(:purchase_order, vendor: vendor)

      visit report_path('items_consumption')
      sleep 2

      page.text.wont_include item1.name # because there are no receives for the order yet
      page.text.wont_include item2.name # because there are no receives for the order yet
      ######## creating one receipt #######
      receipt = create(:purchase_receipt, purchase_order: po, user: @user, created_at: Time.now - 5.days)
      create(:item_receipt, purchase_receipt: receipt, item: item1, quantity: 1, price: 200,
        item_order: create(:item_order, quantity: 2, purchase_order: po, item: item1, item_request: ir1)
      ) # total for the item is 2x200 = $400
      create(:item_receipt, purchase_receipt: receipt, item: item2, quantity: 5, price: 350,
        item_order: create(:item_order, quantity: 10, purchase_order: po, item: item2, item_request: ir2)
      ) # total for the item is 10x350 = $3500
      # total for the order 3500 + 400 = $3900
      #### Receipt end ####

     
      visit report_path('items_consumption')
      sleep 2
 
      find('table.items-consumption tbody tr:nth-child(1) td:nth-child(2)').text.must_equal item1.name
      find('table.items-consumption tbody tr:nth-child(1) td:nth-child(5)').text.must_include "1.0" # avg order qty
      find('table.items-consumption tbody tr:nth-child(1) td:nth-child(6)').text.must_equal "$200.0" # avg order cost

      find('table.items-consumption tbody tr:nth-child(2) td:nth-child(2)').text.must_equal item2.name
      find('table.items-consumption tbody tr:nth-child(2) td:nth-child(5)').text.must_include "5.0" # avg order qty
      find('table.items-consumption tbody tr:nth-child(2) td:nth-child(6)').text.must_equal "$1750.0" # avg order cost

      # create another Request, Order and Receiving:
      pr     = create(:purchase_request)
      ir1    = create(:item_request, purchase_request: pr, item: item1)
      ir2    = create(:item_request, purchase_request: pr, item: item2)
      po     = create(:purchase_order, vendor: vendor)
      ######## creating one receipt #######
      receipt = create(:purchase_receipt, purchase_order: po, user: @user, created_at: Time.now - 5.days)
      create(:item_receipt, purchase_receipt: receipt, item: item1, quantity: 2, price: 200,
        item_order: create(:item_order, quantity: 6, purchase_order: po, item: item1, item_request: ir1)
      ) # total for the item is 6x200 = $1200
      create(:item_receipt, purchase_receipt: receipt, item: item2, quantity: 6, price: 15,
        item_order: create(:item_order, quantity: 20, purchase_order: po, item: item2, item_request: ir2)
      ) # total for the item is 20x15 = $300
      # total for the order 300 + 1200 = $1500
      #### Receipt end ####

      visit report_path('items_consumption')
      sleep 2

      # screenshot_and_open_image
      find('table.items-consumption tbody tr:nth-child(1) td:nth-child(2)').text.must_equal item1.name
      find('table.items-consumption tbody tr:nth-child(1) td:nth-child(5)').text.must_include "1.5" # avg order qty
      find('table.items-consumption tbody tr:nth-child(1) td:nth-child(6)').text.must_equal "$300.0" # avg order cost

      find('table.items-consumption tbody tr:nth-child(2) td:nth-child(2)').text.must_equal item2.name
      find('table.items-consumption tbody tr:nth-child(2) td:nth-child(5)').text.must_include "5.5" # avg order qty
      find('table.items-consumption tbody tr:nth-child(2) td:nth-child(6)').text.must_equal "$920.0" # avg order cost

    end
  end

  describe 'reports kinds' do
    before do
      Report.create(permalink: 'vendor_spend', name: 'Vendor Spend', groups: 'spending')
      Report.create(permalink: 'items_spend', name: 'Items Spend', groups: 'spending')
      Report.create(permalink: 'category_spend', name: 'Category Spend', groups: 'spending')

      Timecop.travel(end_of_month - 1.hour) do
        days_ago = [1, 3, 10, 38, 45]

        category1 = create(:category)
        category2 = create(:category)
        @vendors  = []
        @items    = []
        5.times do |i|
          @vendors[i] = create(:vendor)
          po          = create(:purchase_order, vendor: @vendors[i])
          @items[i]   = create(:item, vendors: [ @vendors[i] ], categories: [i%2==0 ? category1 : category2])
          pr          = create(:purchase_request)

          receipt     = create(:purchase_receipt, purchase_order: po, user: @user, created_at: Time.now - days_ago[i].days)
          ir          = create(:item_request, purchase_request: pr, item: @items[i])
          create(:item_receipt, purchase_receipt: receipt, item: @items[i], quantity: 1, price: i * 100 + 100,
                 item_order: create(:item_order, purchase_order: po, item: @items[i], item_request: ir)
          )
        end
      end
    end


    it "show correct data for vendor spend report", js: true do
      skip "WILL FIX AFTER FINISHING PM"
      Timecop.travel(end_of_month) do
        visit report_path('vendor_spend')
        sleep 2
        page.text.must_include "$100.00"
        page.text.must_include "$200.00"
        page.text.must_include "$300.00"
        page.text.wont_include "$400.00" # prev month
        page.text.wont_include "$500.00" # prev month

        find('#offset-minus').trigger('click')
        sleep 2

        page.text.wont_include "$100.00" # next month
        page.text.wont_include "$200.00" # next month
        page.text.wont_include "$300.00" # next month
        page.text.must_include "$400.00"
        page.text.must_include "$500.00"
      end
    end

    it "show correct data for vendor spend report", js: true do
      skip "WILL FIX AFTER FINISHING PM"
      Timecop.travel(end_of_month) do
        visit report_path('vendor_spend')
        sleep 2
        find("span.text-muted.bold", text: "$100.00")
        find("span.text-muted.bold", text: "$200.00")
        find("span.text-muted.bold", text: "$300.00")
        assert !page.has_content?("span.text-muted.bold", text: "$400.00")
        assert !page.has_content?("span.text-muted.bold", text: "$500.00")

        find('#offset-minus').trigger('click')
        sleep 2

        assert !page.has_content?("span.text-muted.bold", text: "$100.00")
        assert !page.has_content?("span.text-muted.bold", text: "$200.00")
        assert !page.has_content?("span.text-muted.bold", text: "$300.00")
        find("span.text-muted.bold", text: "$400.00")
        find("span.text-muted.bold", text: "$500.00")
      end
    end

    it "shows correct data for items spend report", js: true do
      skip "WILL FIX AFTER FINISHING PM"
      Timecop.travel(end_of_month) do
        visit report_path('items_spend')
        sleep 2

        page.text.must_include "Items Spend"
        page.text.must_include @items[0].name
        page.text.must_include @items[1].name
        page.text.must_include @items[2].name

        find("span.text-muted.bold", text: "$100.00")
        find("span.text-muted.bold", text: "$200.00")
        find("span.text-muted.bold", text: "$300.00")
        assert !page.has_content?("span.text-muted.bold", text: "$400.00")
        assert !page.has_content?("span.text-muted.bold", text: "$500.00")

        find('#offset-minus').trigger('click')
        sleep 2

        assert !page.has_content?("span.text-muted.bold", text: "$100.00")
        assert !page.has_content?("span.text-muted.bold", text: "$200.00")
        assert !page.has_content?("span.text-muted.bold", text: "$300.00")
        find("span.text-muted.bold", text: "$400.00")
        find("span.text-muted.bold", text: "$500.00")
      end
    end

    it "shows correct data for category spend report", js:true do
      skip "WILL FIX AFTER FINISHING PM"
      Timecop.travel(end_of_month) do
        visit report_path('category_spend')
        sleep 2
        page.text.must_include 'Category Spend'

        find("span.text-muted.bold", text: "$200.00")
        find("span.text-muted.bold", text: "$400.00")
        find('#offset-minus').trigger('click')
        sleep 2

        find("span.text-muted.bold", text: "$400.00")
        find("span.text-muted.bold", text: "$500.00")#.count.must_equal 2
      end
    end
  end

  describe 'inventory vs ordering report' do
    before do
      Report.create(permalink: 'inventory_vs_ordering', name: 'Inventory vs Ordering', groups: 'misc')

      Timecop.travel('2013-01-01') do
        @item1 = create(:item)
        @item2 = create(:item)
      end
    end

    it "shows correct data", js:true do
      skip "WILL FIX AFTER FINISHING PM"
      Timecop.travel('2013-01-10') do
        create(:item_request, item: @item1, skip_inventory: true, count: 0)
        create(:item_request, item: @item1, skip_inventory: true, count: 0)
        create(:item_request, item: @item1, skip_inventory: true, count: 0)
        create(:item_request, item: @item1, skip_inventory: true, count: 0)
        create(:item_request, item: @item1, skip_inventory: nil, count: 10)
        create(:item_request, item: @item2, skip_inventory: nil, count: 20)
      end

      Timecop.travel('2013-01-15') do
        create(:item_request, item: @item1, skip_inventory: nil, count: 21)
        create(:item_request, item: @item2, skip_inventory: nil, count: 31)
      end

      Timecop.travel('2013-01-17') do
        create(:item_request, item: @item1, skip_inventory: nil, count: 22)
      end

      Timecop.travel('2013-01-18') do
        visit report_path('inventory_vs_ordering')
        has_content?('Inventory vs Ordering').must_equal true
        sleep 3

        within("table.searchable-table tbody tr:nth-child(1)") do
          find('td:nth-child(1)').has_content?(@item1.name).must_equal true
          find('td:nth-child(2)').has_content?(3).must_equal true
          find('td:nth-child(3)').has_content?(0).must_equal true
        end
      end
    end
  end
end
