require 'minitest/autorun'
require 'test_helper'

describe ReportsController do
  include Devise::TestHelpers

  before do
    @user = create(:user)
    sign_in @user
  end

  describe '#vendor_spend_data' do
    it "must return correct orders for a given day" do
      vendor   = FactoryGirl.create(:vendor, property: @user.all_properties.first)
      order    = FactoryGirl.create(:purchase_order, vendor: vendor)
      receipt1 = FactoryGirl.create(:purchase_receipt, purchase_order: order, freight_shipping: 15.0)
      FactoryGirl.create(:item_receipt, purchase_receipt: receipt1)
      get :vendor_spend, from: (Time.now - 7.days).strftime("%d-%m-%Y"), to: (Time.now).strftime("%d-%m-%Y"), format: :json
      parsed_body = JSON.parse(response.body)
      assert parsed_body.count == 1
    end
  end

  describe "#category_spend_data" do

    it "returns nothing" do
      get :category_spend, format: :json
      body = JSON.parse(response.body)
      assert body.blank?   
    end

    it "returns correct report data" do
      @irs = []
      10.times { |i| @irs << FactoryGirl.create(:item_receipt, quantity: (i+1)*10, price:  (i+1)*5) }
      get :category_spend, format: :json
      body = JSON.parse(response.body)

      body.map{|x| x['spend'].to_f }.sort.each_with_index do |p, index|
        p.must_equal (index+1)*(index+1)*50
      end
    end

    describe "complex stuff" do
      let(:end_of_month){ Time.now.end_of_month - 2.days }
      before do
        Report.create(permalink: 'category_spend', name: 'Category Spend', groups: 'spending')

        Timecop.travel(end_of_month - 1.hour) do
          days_ago = [1, 3, 10, 38, 45]

          category1 = create(:category)
          category2 = create(:category)
          @vendors  = []
          @items    = []
          days_ago.each_with_index do |days_count, i|
            @vendors[i] = create(:vendor)
            po          = create(:purchase_order, vendor: @vendors[i])
            @items[i]   = create(:item, vendors: [ @vendors[i] ], categories: [i%2==0 ? category1 : category2])
            pr          = create(:purchase_request)

            receipt     = create(:purchase_receipt, purchase_order: po, user: @user, created_at: Time.now - days_count.days)
            ir          = create(:item_request, purchase_request: pr, item: @items[i])
            create(:item_receipt, purchase_receipt: receipt, item: @items[i], quantity: 1, price: i * 100 + 100,
                   item_order: create(:item_order, purchase_order: po, item: @items[i], item_request: ir)
            )
          end
        end
      end

      it "should return correct data for current month" do
        get :category_spend, from: Time.now.beginning_of_month.to_s, to: Time.now.end_of_month.to_s, format: :json
        body = JSON.parse(response.body)
        body.map{|cs| cs['spend']}.must_include "200.00", "400.00"
      end

      it "should return correct data for past month" do
        get :category_spend, from: (Time.now - 1.month).beginning_of_month.to_s, to: (Time.now - 1.month).end_of_month.to_s, format: :json
        body = JSON.parse(response.body)
        body.map{|cs| cs['spend']}.must_include "400.00", "500.00"
      end

    end



  end

  describe "#items_spend_data" do

    before do
      @items = []
      3.times { |i| @items << FactoryGirl.create(:item_with_vendor_item) }
      @receipts = []
      6.times { |i| @receipts << FactoryGirl.create(:item_receipt, quantity: i+1, price: 10, item: @items[i % 3]) }

      @prs = []
      6.times { |i| @prs << FactoryGirl.create(:purchase_receipt, item_receipts: [@receipts[i]], created_at: (Time.now - (i+1).days)) }
    end

    it "returns all data if there's no date range" do
      get :items_spend, from: (Date.today - 7.days).to_s, to: Date.today.to_s, format: :json
      body = JSON.parse(response.body)
      
      body[0]['spend'].to_f.must_equal 50
      body[0]['name'].must_equal @items[0].name
      body[0]['num_orders'].must_equal 2
      body[1]['spend'].to_f.must_equal 70
      body[1]['name'].must_equal @items[1].name
      body[1]['num_orders'].must_equal 2
      body[2]['spend'].to_f.must_equal 90
      body[2]['name'].must_equal @items[2].name
      body[2]['num_orders'].must_equal 2
    end

    it "returns scoped data for a given day" do
      skip "WILL FIX AFTER FINISHING PM"
      6.times do |i|
        get :items_spend, from: Date.today - (i+1).days, to: Date.today, format: :json
        body = JSON.parse(response.body)

        body.count.must_equal (i+1) > 3 ? 3 : (i+1)
      end
    end
  end

  describe "#item_orders_chart_data" do
    it "returns correct data" do
      item = create(:item)
      pos = create_list(:purchase_order, 5, created_at: '2014-1-15')
      pos += create_list(:purchase_order, 3, created_at: '2014-9-15')

      pos.each do |po|
        receipt = create(:purchase_receipt, purchase_order: po, user: @user)
        create(:item_receipt, purchase_receipt: receipt, item: item, quantity: 1, price: 200,
          item_order: create(:item_order, quantity: 2, purchase_order: po, item: item)
        ) 
      end

      get :item_orders_chart_data, id: item.id, from: '01-07-2014', to: '30-09-2014', format: :json

      body = JSON.parse(response.body)

      body[-3].last.must_equal 5
      body.last.last.must_equal 3
    end
  end

  # USER PERMISSIONS:

  describe 'permissions' do
    before :all do 
      Report.create(Report::ALL_KINDS)
    end

    for role_name in %w(agm gm corporate manager)

      describe role_name do
        let(:user){ create(:user, current_property_role: Role.send(role_name)) }

        before do
          sign_in user
        end

        describe '#vendor_spend' do
          it 'should have access to #vendor_spend' do
            get :show, id: 'vendor_spend'
            assert_response :success
          end

          it 'should have access to #vendor_spend_data' do
            get :vendor_spend, from: (Time.now - 7.days).strftime("%d-%m-%Y"), to: (Time.now).strftime("%d-%m-%Y"), format: :json
            assert_response :success
          end
        end

        describe "#category_spend" do
          it "should have access to #category_spend" do
            get :show, id: 'category_spend'
            assert_response :success
          end

          it "should have access to #category_spend_data" do
            get :category_spend, from: (Time.now - 7.days).strftime("%d-%m-%Y"), to: (Time.now).strftime("%d-%m-%Y"), format: :json
            assert_response :success
          end
        end

        describe "#item_price_variance" do
          it "should have access to #item_price_variance" do
            get :show, id: 'item_price_variance'
            assert_response :success
          end

          it "should have access to #item_price_variance_data" do
            get :item_price_variance, from: (Time.now - 7.days).strftime("%d-%m-%Y"), to: (Time.now).strftime("%d-%m-%Y"), format: :json
            assert_response :success
          end
        end

        describe "#items_consumption" do
          it "should have access to #items_consumption" do
            get :show, id: 'items_consumption'
            assert_response :success
          end

          it "should have access to #items_consumption_data" do
            get :items_consumption, from: (Time.now - 7.days).strftime("%d-%m-%Y"), to: (Time.now).strftime("%d-%m-%Y")
            assert_response :success
          end

          it "should have access to #item_avg_month_orders_chart_data" do
            item = create(:item)
            get :item_orders_chart_data, id: item.id, from: (Time.now - 6.month).strftime("%d-%m-%Y"), to: (Time.now).strftime("%d-%m-%Y")
            assert_response :success
          end
        end


        describe "#category_spend" do
          it "should have access to #category_spend" do
            get :show, id: 'category_spend'
            assert_response :success
          end

          it "should have access to #category_spend_data" do
            get :category_spend, from: (Time.now - 7.days).strftime("%d-%m-%Y"), to: (Time.now).strftime("%d-%m-%Y")
            assert_response :success
          end
        end

        describe "#items_spend" do
          it "should have access to #items_spend" do
            get :show, id: 'items_spend'
            assert_response :success
          end

          it "should have access to #items_spend_data" do
            get :items_spend, from: (Time.now - 7.days).strftime("%d-%m-%Y"), to: (Time.now).strftime("%d-%m-%Y")
            assert_response :success
          end
        end

      end

    end



  end
end
