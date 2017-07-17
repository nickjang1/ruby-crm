require 'test_helper'

describe PurchaseRequestsController do
  include Devise::TestHelpers

  it "should render correct vendors number for PR listing" do
    sign_in create(:user)
    vendors = create_list(:vendor, 5)
    item1   = create(:item)
    item2   = create(:item)
    create(:vendor_item, vendor: vendors[0], item: item1, preferred: true)
    create(:vendor_item, vendor: vendors[1], item: item1)
    create(:vendor_item, vendor: vendors[2], item: item1)
    create(:vendor_item, vendor: vendors[3], item: item2, preferred: true)
    create(:vendor_item, vendor: vendors[4], item: item2)
    pr = create(:purchase_request)
    pr.item_requests << create(:item_request, item: item1)
    pr.item_requests << create(:item_request, item: item2)
    get :index
    assert_response :success
    response.body.must_include "2 vendors"
  end
  
  it 'should render active/closed PR listing' do
    user = create(:user)
    sign_in user
    PurchaseRequest.destroy_all
    vendors = create_list(:vendor, 5)
    item1   = create(:item)
    item2   = create(:item)
    create(:vendor_item, vendor: vendors[0], item: item1, preferred: true)
    create(:vendor_item, vendor: vendors[1], item: item1)
    create(:vendor_item, vendor: vendors[2], item: item1)
    create(:vendor_item, vendor: vendors[3], item: item2, preferred: true)
    create(:vendor_item, vendor: vendors[4], item: item2)
    pr = create(:purchase_request)
    pr_closed = create(:purchase_request, state: :ordered)
    pr.item_requests << create(:item_request, item: item1)
    pr.item_requests << create(:item_request, item: item2)
    pr_closed.item_requests << create(:item_request, item: item1)
    pr_closed.item_requests << create(:item_request, item: item2)
    pr_closed.item_requests << create(:item_request, item: item2)
    
    get :index
    assert_response :success
    response.body.must_include "2 vendors"
    response.body.wont_include '3 vendors'
    
    get :index, {scope: 'closed'}
    assert_response :success
    assigns['purchase_requests'].count.must_equal 1
    assigns['purchase_requests'].first.must_equal pr_closed
  end

  describe 'accept/reject pr with changes on 3rd step' do
    before do
      sign_in create(:user)
    end

    it 'should store prev quantity for item_requests on step 3 if quantity changed' do
      pr = create(:purchase_request, state: :completed)
      ir = create(:item_request, purchase_request: pr, quantity: 123)
      put :update, id: pr.id, commit: 'reject', purchase_request: { item_requests_attributes: {"0"=>{ id: ir.id, quantity: 9999999 }}, rejection_reason: 'some reason' }
      ir.reload
      ir.prev_quantity.must_equal 123
      ir.quantity.must_equal 9999999
    end

    it 'should create notification if pr rejected with modifications to quantities' do
      pr = create(:purchase_request, state: :completed)
      ir = create(:item_request, purchase_request: pr, quantity: 123)
      Notification.count.must_equal 0
      put :update, id: pr.id, commit: 'reject', purchase_request: { item_requests_attributes: {"0"=>{ id: ir.id, quantity: 9999999 }}, rejection_reason: 'some reason' }
      Notification.count.must_equal 1
    end

    it 'should not create notification if pr rejected without modifications to quantities' do
      pr = create(:purchase_request, state: :completed)
      ir = create(:item_request, purchase_request: pr, quantity: 123)
      Notification.count.must_equal 0
      put :update, id: pr.id, commit: 'reject', purchase_request: { item_requests_attributes: {"0"=>{ id: ir.id, quantity: 123 }}, rejection_reason: 'some reason' }
      Notification.count.must_equal 0
    end
  end
  
  describe "corporate" do
    before do
      sign_in create(:user, current_property_role: Role.corporate)
    end

    describe "GET#index" do
      it "corporate should see prs with completed status & total > any GMs order_approval_limit" do
        skip "WAIT UNTILL CORPORATE SETUP HAS BEEN FINISHED"
        create(:user, current_property_role: Role.gm, order_approval_limit: 0) # GM in the same property
        pr = create(:purchase_request, :with_items, state: 'completed')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        create_list(:purchase_request, 2, :with_items, state: 'inventory')
        get :index
        assert_response :success
        assert_select 'table tbody tr', 1
      end

      it "corporate should not see prs with request status & total > any GMs order_approval_limit" do
        skip "WAIT UNTILL CORPORATE SETUP HAS BEEN FINISHED"
        create(:user, current_property_role: Role.gm, order_approval_limit: 0) # GM in the same property
        pr = create(:purchase_request, :with_items, state: 'request')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        create_list(:purchase_request, 2, :with_items, state: 'inventory')
        get :index
        assert_response :success
        assert_select 'table tbody tr', 0
      end

      it "corporate should not see prs with completed status & total < any GMs order_approval_limit" do
        skip "WAIT UNTILL CORPORATE SETUP HAS BEEN FINISHED"
        create(:user, current_property_role: Role.gm, order_approval_limit: 2100) # GM in the same property
        pr = create(:purchase_request, :with_items, state: 'completed')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        create_list(:purchase_request, 2, :with_items, state: 'inventory')
        get :index
        assert_response :success
        assert_select 'table tbody tr', 0
      end
    end

    describe "GET#show" do
      it "corporate should have no list access" do
        create(:purchase_request, :with_items)
        get :show, id: PurchaseRequest.first.id
        assert_redirected_to authenticated_root_path
      end
    end

    describe "GET#new" do
      it "corporate should have no new access" do
        get :new
        assert_redirected_to authenticated_root_path
      end
    end

    describe "POST#create" do
      it "corporate should have no create access" do
        post :create, tag: {name: "NEW LIST"}
        assert_redirected_to authenticated_root_path
      end
    end

    describe "GET#edit" do
      it "corporate should have no edit access for prs with not completed status" do
        pr = create(:purchase_request, :with_items, state: 'inventory')
        get :edit, id: pr.id
        assert_redirected_to authenticated_root_path
      end

      it "corporate should have edit access for prs with completed status" do
        pr = create(:purchase_request, :with_items, state: 'completed')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        get :edit, id: pr.id
        assert_response :success
      end
    end

    describe "PUT#update" do
      it "corporate should have no put access" do
        create(:purchase_request, :with_items)
        put :update, id: PurchaseRequest.first.id
        assert_redirected_to authenticated_root_path
      end
    end

    describe "GET#inventory_print" do
      it "corporate should have no list access" do
        create(:purchase_request, :with_items)
        get :inventory_print, id: PurchaseRequest.first.id
        assert_redirected_to authenticated_root_path
      end
    end
  end

  describe "agm" do
    let(:user){ create(:user, current_property_role: Role.agm) }

    before do
      create_list(:purchase_request, 5, :with_items)
      sign_in user
    end

    describe "GET#index" do
      it "agm should have list access" do
        get :index
        assert_response :success
      end
    end

    describe "GET#new" do
      it "agm should have new access" do
        get :new
        assert_response :success
      end
    end

    describe "POST#create" do
      it "agm should have create access" do
        post :create, commit: 'next'
        assert_redirected_to edit_purchase_request_path(PurchaseRequest.last)
      end
    end

    describe "GET#edit" do
      it "agm should have edit access" do
        get :edit, id: PurchaseRequest.first.id
        assert_response :success
      end

      it "gm should have approve access purchase requests where total_price <= order_approval_limit" do
        pr = PurchaseRequest.first
        pr.update_attributes(state: 'completed')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        user.current_property_user_role.update_attributes order_approval_limit: 2100 # $2100
        get :edit, id: pr.id
        assert_select '.page-header .btn-success', 1
      end

      it "gm should not have approve access purchase requests where total_price > order_approval_limit" do
        pr = PurchaseRequest.first
        pr.update_attributes(state: 'completed')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        user.current_property_user_role.update_attributes order_approval_limit: 1900 # $2100
        get :edit, id: pr.id
        assert_select '.page-header .btn-success', 0
      end
    end

    describe "PUT#update" do
      it "agm should have put access" do
        pr = PurchaseRequest.last
        put :update, id: pr.id, commit: 'next'#, purchase_request: {name: "NEW"}, id: PurchaseRequest.first.id
        assert_redirected_to edit_purchase_request_path(pr)
      end
    end

    describe "GET#inventory_print" do
      it "should render inventory_print" do
        get :inventory_print, id: PurchaseRequest.first.id
        assert_response :success
      end
    end
  end

  describe "gm" do
    let(:user){ create(:user, current_property_role: Role.gm) }

    before do
      create_list(:purchase_request, 5, :with_items)
      sign_in user
    end

    describe "GET#index" do
      it "gm should have list access" do
        get :index
        assert_response :success
      end
    end

    describe "GET#new" do
      it "gm should have new access" do
        get :new
        assert_response :success
      end
    end

    describe "POST#create" do
      it "gm should have create access" do
        post :create, commit: 'next'
        assert_redirected_to edit_purchase_request_path(PurchaseRequest.last)
      end
    end

    describe "GET#edit" do
      it "gm should have edit access" do
        get :edit, id: PurchaseRequest.first.id
        assert_response :success
      end

      it "gm should have approve access purchase requests where total_price <= order_approval_limit" do
        pr = PurchaseRequest.first
        pr.update_attributes(state: 'completed')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        user.current_property_user_role.update_attributes order_approval_limit: 2100 # $2100
        get :edit, id: pr.id
        assert_select '.page-header .btn-success', 1
      end

      it "gm should not have approve access purchase requests where total_price > order_approval_limit" do
        pr = PurchaseRequest.first
        pr.update_attributes(state: 'completed')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        user.current_property_user_role.update_attributes order_approval_limit: 1900 # $2100
        get :edit, id: pr.id
        assert_select '.page-header .btn-success', 0
      end

    end

    describe "PUT#update" do
      it "gm should have put access" do
        pr = PurchaseRequest.last
        put :update, id: pr.id, commit: 'next'#, purchase_request: {name: "NEW"}, id: PurchaseRequest.first.id
        assert_redirected_to edit_purchase_request_path(pr)
      end
    end

    describe "GET#inventory_print" do
      it "should render inventory_print" do
        get :inventory_print, id: PurchaseRequest.first.id
        assert_response :success
      end
    end
  end

  describe "manager" do
    let(:user){ create(:user, current_property_role: Role.manager) }
    let(:user2){ create(:user, current_property_role: Role.manager) }
    let(:property2){ create(:property) }
    let(:managable_lists){ create_list(:purchase_request, 2, :with_items, user: user) }
    let(:non_managable_lists){ create_list(:purchase_request, 1, :with_items, user: user2) }
    
    before do
      sign_in user
    end

    describe "GET#index" do
      it "manager can see only their own created purchase_requests" do
        non_managable_lists # call to let 'em be created
        managable_lists     # call to let 'em be created
        get :index
        assert_select 'table.table tbody tr', 2
      end
      
      it "manager can see their old purchase requests are already ordered" do
        managable_lists.each do |pr|
          pr.state = :ordered
          pr.save
        end
        non_managable_lists.each do |pr|
          pr.state = :ordered
          pr.save
        end
        get :index, {scope: :closed}
        assert_select 'table.table tbody tr', 2
      end
    end

    describe "GET#new" do
      it "manager should have new access" do
        get :new
        assert_response :success
      end
    end

    describe "POST#create" do
      it "manager should have create access" do
        post :create, commit: 'next'#, purchase_request: {}
        assert_redirected_to edit_purchase_request_path(PurchaseRequest.last)
      end
    end

    describe "GET#edit" do
      it "manager should not have edit access for list that doesn't belong to him" do
        Property.current_id = property2.id
        get :edit, id: non_managable_lists.first.id
        assert_redirected_to authenticated_root_path
      end

      it "manager should have edit access for list that belongs to him" do
        get :edit, id: managable_lists.first.id
        assert_response :success
      end

      it "manager should have approve access for list that belongs to him, total_price <= order_approval_limit" do
        pr = managable_lists.first
        pr.update_attributes(state: 'completed')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        user.current_property_user_role.update_attributes order_approval_limit: 2100 # $2100
        get :edit, id: pr.id
        assert_select '.page-header .btn-success', 1
      end

      it "manager should not have approve access for list that doesn't belongs to him, total_price <= order_approval_limit" do
        pr = non_managable_lists.first
        pr.update_attributes(state: 'completed')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        user.current_property_user_role.update_attributes order_approval_limit: 2100 # $2100
        get :edit, id: pr.id
        assert_select '.page-header .btn-success', 0
      end

      it "manager should not have approve access for list that belongs to him, total_price > order_approval_limit" do
        pr = managable_lists.first
        pr.update_attributes(state: 'completed')
        pr.item_requests.each do |ir| # total price is $2000
          ir.update_attributes quantity: 2, count: 1
        end
        user.current_property_user_role.update_attributes order_approval_limit: 1900 # $2100
        get :edit, id: pr.id
        assert_select '.page-header .btn-success', 0
      end
    end

    describe "PUT#update" do
      it "manager should not have update access for list that doesn't belong to him" do
        put :update, id: non_managable_lists.first.id,  commit: 'next'
        assert_redirected_to authenticated_root_path
      end

      it "manager should have update access for list that belongs to him" do
        # put :update, id: managable_lists.first.id
        pr = managable_lists.first
        put :update, id: pr.id, commit: 'next'#, purchase_request: {name: "NEW"}, id: PurchaseRequest.first.id
        assert_redirected_to edit_purchase_request_path(pr)
      end
    end

    describe "GET#inventory_print" do
      it "should render inventory_print for own PR" do
        pr = managable_lists.first
        get :inventory_print, id: pr.id
        assert_response :success
      end
      it "should redirect inventory_print for non own PR" do
        pr = non_managable_lists.first
        get :inventory_print, id: pr.id
        assert_redirected_to authenticated_root_path
      end
    end
  end
end
