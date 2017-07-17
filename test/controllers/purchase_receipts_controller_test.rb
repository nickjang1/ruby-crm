require 'minitest/autorun'
require 'test_helper'

describe PurchaseReceiptsController do
  include Devise::TestHelpers

  describe "manager" do
    let(:user){ create(:user, current_property_role: Role.manager) }
    let(:user2){ create(:user, current_property_role: Role.manager) }

    before do
      sign_in user
    end

    describe "GET#new" do
      it "should give access to new form for own order" do
        order = create(:purchase_order, state: 'open', purchase_request: create(:purchase_request, user: user))
        get :new, purchase_order_id: order.id
        assert_response :success
      end

      it "should not give access to new form for not own order" do
        order = create(:purchase_order, state: 'open', purchase_request: create(:purchase_request, user: user2))
        get :new, purchase_order_id: order.id
        assert_redirected_to authenticated_root_path
        flash[:alert].must_equal "You are not authorized to access this page."
      end
    end

    describe "POST#create" do
      it "should give access to new form for own order" do
        order = create(:purchase_order, state: 'open', purchase_request: create(:purchase_request, user: user))
        post :create, purchase_receipt: { purchase_order_id: order.id }
        assert_redirected_to purchase_orders_path
      end

      it "should not give access to new form for not own order" do
        order = create(:purchase_order, state: 'open', purchase_request: create(:purchase_request, user: user2))
        post :create, purchase_receipt: { purchase_order_id: order.id }
        assert_redirected_to authenticated_root_path
        flash[:alert].must_equal "You are not authorized to access this page."
      end
    end
  end

  describe "gm" do
    let(:user){ create(:user, current_property_role: Role.gm) }
    let(:user2){ create(:user, current_property_role: Role.gm) }

    before do
      sign_in user
    end

    describe "GET#new" do
      it "should give access to new form for own order" do
        order = create(:purchase_order, state: 'open', user: user)
        get :new, purchase_order_id: order.id
        assert_response :success
      end

      it "should give access to new form for non own order" do
        order = create(:purchase_order, state: 'open', user: user2)
        get :new, purchase_order_id: order.id
        assert_response :success
      end
    end

    describe "POST#create" do
      it "should give access to new form for own order" do
        order = create(:purchase_order, state: 'open', user: user)
        post :create, purchase_receipt: { purchase_order_id: order.id }
        assert_redirected_to purchase_orders_path
      end

      it "should give access to new form for not own order" do
        order = create(:purchase_order, state: 'open', user: user2)
        post :create, purchase_receipt: { purchase_order_id: order.id }
        assert_redirected_to purchase_orders_path
      end
    end
  end

  describe "agm" do
    let(:user){ create(:user, current_property_role: Role.agm) }
    let(:user2){ create(:user, current_property_role: Role.agm) }

    before do
      sign_in user
    end

    describe "GET#new" do
      it "should give access to new form for own order" do
        order = create(:purchase_order, state: 'open', user: user)
        get :new, purchase_order_id: order.id
        assert_response :success
      end

      it "should give access to new form for non own order" do
        order = create(:purchase_order, state: 'open', user: user2)
        get :new, purchase_order_id: order.id
        assert_response :success
      end
    end

    describe "POST#create" do
      it "should give access to new form for own order" do
        order = create(:purchase_order, state: 'open', user: user)
        post :create, purchase_receipt: { purchase_order_id: order.id }
        assert_redirected_to purchase_orders_path
      end

      it "should give access to new form for not own order" do
        order = create(:purchase_order, state: 'open', user: user2)
        post :create, purchase_receipt: { purchase_order_id: order.id }
        assert_redirected_to purchase_orders_path
      end
    end
  end

  # describe "corporate" do
  #
  #   Corporate cannot access orders list page at all, so he can't create receipts as well 
  #
  # end

end
