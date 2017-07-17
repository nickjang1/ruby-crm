require 'minitest/autorun'
require 'test_helper'

describe PagesController do
  include Devise::TestHelpers

  describe "manager" do
    let(:user){ create(:user, current_property_role: Role.manager) }
    let(:user2){ create(:user, current_property_role: Role.manager) }

    before do
      sign_in user
    end

    describe "GET#dashboard" do
      it 'should not be able to see hotel settings' do
        get :dashboard
        response.body.wont_include 'Hotel Settings'
      end

      it "should render own created PRs" do
        create_list(:purchase_request, 2, user: user)
        create_list(:purchase_request, 1, user: user2) # should not be seen
        get :dashboard
        assert_select '#orders table tbody tr', 2
      end

      it "should render POs created from own PRs" do
        pr1 = create(:purchase_request, state: 'ordered', user: user)
        pr2 = create(:purchase_request, state: 'ordered', user: user2)
        create(:purchase_order, purchase_request: pr1, state: 'open')
        create(:purchase_order, purchase_request: pr2, state: 'open') # should not be seen

        get :dashboard
        assert_select '#orders table tbody tr', 1
      end

      it "should not render approve button on PR that cannot be approved by this manager" do
        user.update_attributes(order_approval_limit: 100)
        pr1 = create(:purchase_request, :with_items, state: 'completed', user: user)
        pr1.item_requests.update_all(quantity: 0, count: 0)
        pr2 = create(:purchase_request, :with_items, state: 'completed', user: user)
        pr2.item_requests.update_all(quantity: 2, count: 1)# total price is $2000
        get :dashboard
        assert_select '#orders .btn-success', {count: 1, html: /Approve/}
      end

      it "should render own created lists" do
        create_list(:list, 2, user: user)
        create_list(:list, 1, user: user2) # should not be seen
        get :dashboard
        assert_select '#lists table tbody tr', 2
      end

      it "should load spend vs budgets data" do
        vendor  = create(:vendor)

        category1 = create(:category, name: "CATEGORY1")
        po      = create(:purchase_order, vendor: vendor)
        item    = create(:item, vendors: [ vendor ], categories: [category1])
        receipt = create(:purchase_receipt, purchase_order: po, user: user)
        ir      = create(:item_request, item: item)
        create(:item_receipt, purchase_receipt: receipt, item: item, quantity: 1, price: 1400,
          item_order: create(:item_order, purchase_order: po, item: item, item_request: ir)
        )

        category2 = create(:category, name: "CATEGORY2")
        po      = create(:purchase_order, vendor: vendor)
        item    = create(:item, vendors: [ vendor ], categories: [category2])
        receipt = create(:purchase_receipt, purchase_order: po, user: user)
        ir      = create(:item_request, item: item)
        create(:item_receipt, purchase_receipt: receipt, item: item, quantity: 1, price: 800,
          item_order: create(:item_order, purchase_order: po, item: item, item_request: ir)
        )

        create(:budget, user: user, category: category1, amount: 1000)
        create(:budget, user: user, category: category2, amount: 1650)

        xhr :get, :spend_vs_budgets_data
        parsed_body = JSON.parse(response.body)

        parsed_body['data']['budget'].count.must_equal 2
        parsed_body['data']['budget'].must_include 1000.0
        parsed_body['data']['budget'].must_include 1650.0
        parsed_body['data']['spend'].count.must_equal 2
        parsed_body['data']['spend'].must_include 1400.0
        parsed_body['data']['spend'].must_include 800.0

        parsed_body['categories'].count.must_equal 2
        parsed_body['categories'].must_include "CATEGORY1"
        parsed_body['categories'].must_include "CATEGORY2"
      end
    end
  end

  describe "gm" do
    let(:user){ create(:user, current_property_role: Role.gm) }
    let(:user2){ create(:user, current_property_role: Role.manager) }

    before do
      sign_in user
    end

    it 'should be able to see hotel settings' do
      get :dashboard
      assert_select('a', text: 'Hotel Settings')
    end

    it "should render all PRs" do
      create_list(:purchase_request, 2, user: user)
      create_list(:purchase_request, 1, user: user2)
      get :dashboard
      assert_select '#orders table tbody tr', 3
    end

    it "should render all POs in the property" do
      pr1 = create(:purchase_request, state: 'ordered', user: user)
      pr2 = create(:purchase_request, state: 'ordered', user: user2)
      create(:purchase_order, purchase_request: pr1, state: 'open')
      create(:purchase_order, purchase_request: pr2, state: 'open')
      get :dashboard
      assert_select '#orders table tbody tr', 2
    end

    it "should render approve button on all PRs" do
      user.update_attributes(order_approval_limit: 100)
      pr1 = create(:purchase_request, :with_items, state: 'completed', user: user)
      pr2 = create(:purchase_request, :with_items, state: 'completed', user: user)
      pr2.item_requests.each do |ir| # total price is $2000
        ir.update_attributes quantity: 2, count: 1
      end
      get :dashboard
      assert_select '#orders .btn-success', {count: 2, html: /Approve/}
    end

    it "should render all lists" do
      create_list(:list, 2, user: user)
      create_list(:list, 1, user: user2) # should not be seen
      get :dashboard
      assert_select '#lists table tbody tr', 3
    end
  end

  describe "agm" do
    let(:user){ create(:user, current_property_role: Role.agm) }
    let(:user2){ create(:user, current_property_role: Role.manager) }

    before do
      sign_in user
    end

    it 'should be able to see hotel settings' do
      get :dashboard
      response.body.wont_include 'Hotel Settings'
    end

    it "should render all PRs" do
      create_list(:purchase_request, 2, user: user)
      create_list(:purchase_request, 1, user: user2)
      get :dashboard
      assert_select '#orders table tbody tr', 3
    end

    it "should render all POs in the property" do
      pr1 = create(:purchase_request, state: 'ordered', user: user)
      pr2 = create(:purchase_request, state: 'ordered', user: user2)
      create(:purchase_order, purchase_request: pr1, state: 'open')
      create(:purchase_order, purchase_request: pr2, state: 'open')
      get :dashboard
      assert_select '#orders table tbody tr', 2
    end

    it "should render approve button on all PRs" do
      user.update_attributes(order_approval_limit: 100)
      pr1 = create(:purchase_request, :with_items, state: 'completed', user: user)
      pr2 = create(:purchase_request, :with_items, state: 'completed', user: user)
      pr2.item_requests.each do |ir| # total price is $2000
        ir.update_attributes quantity: 2, count: 1
      end
      get :dashboard
      assert_select '#orders .btn-success', {count: 2, html: /Approve/}
    end

    it "should render all lists" do
      create_list(:list, 2, user: user)
      create_list(:list, 1, user: user2) # should not be seen
      get :dashboard
      assert_select '#lists table tbody tr', 3
    end

    it "should render all tasks" do
      create_list(:purchase_request, 20, state: 'completed', user: user)
      get :dashboard
      assigns(:requests_and_orders).size.must_equal 20
    end

    it "should should order tasks by state" do
      create(:purchase_request, state: 'completed', user: user)
      create(:purchase_request, state: 'request', user: user)
      create(:purchase_request, state: 'completed', user: user)
      get :dashboard
      assigns(:requests_and_orders).map(&:state).must_equal ['completed', 'completed', 'request']
    end
  end

  # describe "corporate" do
  #   No specifications given for corporate
  # end

end
