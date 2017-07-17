require 'minitest/autorun'
require 'test_helper'

describe PurchaseOrdersController do
  include Devise::TestHelpers

  before do
    @user = create(:user)
    sign_in @user
  end

  it 'must list all purchase orders for the current property' do
    purchase_orders = create_list(:purchase_order, 4, property: @user.properties.first, state: 'open')
    get :index

    purchase_orders.each do |purchase_order|
      response.body.must_include purchase_order.number
    end
  end

  it 'does not show orders for properties to which a user does not belong' do
    other_user = nil
    create(:property).run_block do
      other_user = create(:user, current_property_role: Role.gm)
    end
    po = create(:purchase_order, user: other_user, property: other_user.properties.first)
    get :index
    response.body.wont_include("##{po.id.to_s.rjust(5, '0')}")
  end

  describe "GET#index" do
    describe 'totals shown on listing' do
      let(:po) { create(:purchase_order, user: @user, state: 'open')}

      before do
        po.item_orders << create(:item_order, quantity: 2, price: 10)
      end

      it 'is based on the item price when order is open' do
        get :index
        assigns[:purchase_orders].first.total_cost.must_equal 20
      end

      it 'is based on the receiving price when partially received with 1 receiving' do
        pr = build(:purchase_receipt, purchase_order: po)
        pr.item_receipts.first.quantity = 1
        pr.item_receipts.first.price = 9 
        pr.save

        get :index

        assigns[:purchase_orders].first.total_price.must_equal 18
      end

      it 'is based on weighted average of the receiving prices when partially received with multiple receipts' do
        po.item_orders.first.update_attributes(quantity: 4)

        pr = build(:purchase_receipt, purchase_order: po)
        pr.item_receipts.first.quantity = 1
        pr.item_receipts.first.price = 20 
        pr.save

        pr = build(:purchase_receipt, purchase_order: po)
        pr.item_receipts.first.quantity = 2
        pr.item_receipts.first.price = 40 
        pr.save

        get :index

        assigns[:purchase_orders].first.total_price.must_equal 133.33
      end
    end
  end

  describe "gm" do
    let(:user){ create(:user, current_property_role: Role.gm) }
    let(:user2){ create(:user, current_property_role: Role.gm) }

    before do
      create_list(:purchase_order, 2, state: 'open', user: user)
      create_list(:purchase_order, 1, state: 'open', user: user2)
      sign_in user
    end

    describe "GET#index" do
      it "gm should have list access" do
        get :index
        assert_select 'table tbody tr', 3
      end
    end
  end

  describe "agm" do
    let(:user){ create(:user, current_property_role: Role.agm) }
    let(:user2){ create(:user, current_property_role: Role.agm) }

    before do
      create_list(:purchase_order, 2, state: 'open', user: user)
      create_list(:purchase_order, 1, state: 'open', user: user2)
      sign_in user
    end

    describe "GET#index" do
      it "agm should have list access" do
        get :index
        assert_select 'table tbody tr', 3
      end
    end
  end


  describe "manager" do
    let(:user){ create(:user, current_property_role: Role.manager) }
    let(:user2){ create(:user, current_property_role: Role.manager) }

    before do
      sign_in user
    end

    describe "GET#index" do
      it "manager should have list access to POs created from own PRs" do
        create_list(:purchase_order, 2, state: 'open', user: user)
        create_list(:purchase_order, 1, state: 'open', user: user2)
        pr1 = create(:purchase_request, state: 'ordered', user: user)
        pr2 = create(:purchase_request, state: 'ordered', user: user2)
        create(:purchase_order, purchase_request: pr1, state: 'open')
        create(:purchase_order, purchase_request: pr2, state: 'open') # should not be seen

        get :index
        assert_select 'table tbody tr', 3
      end
    end

    describe "GET#show" do
      it "should not give show access to POs not created from own PRs" do
        pr = create(:purchase_order, state: 'open', user: user2, purchase_request: create(:purchase_request, user: user2))
        get :show, id: pr.id
        assert_response :redirect
        flash[:alert].must_equal "You are not authorized to access this page."
      end

      it "should give show access to orders requested by manager" do
        pr = create(:purchase_order, state: 'open', user: user2, purchase_request: create(:purchase_request, user: user))
        get :show, id: pr.id
        assert_response :success
      end
    end
  end

  describe "corporate" do
    let(:user){ create(:user, current_property_role: Role.corporate) }

    before do
      create_list(:purchase_order, 2, state: 'open', user: user)
      sign_in user
    end

    describe "GET#index" do
      it "corporate should not have list access" do
        get :index
        assert_response 200
      end
    end

    describe "GET#show" do
      it "corporate should not have show access" do
        pr = create(:purchase_order, state: 'open', user: user)
        get :show, id: pr.id
        assert_response 200
      end
    end
  end

end
