require 'minitest/autorun'
require 'test_helper'

describe ItemsController do
  include Devise::TestHelpers

  describe 'vendors counter' do
    before do
      sign_in create(:user)
    end

    it 'should display + X more vendors for item that have more than 1 vendor' do
      i = create(:item)
      i.vendor_items << create(:vendor_item, preferred: true, vendor: create(:vendor))
      i.vendor_items << create(:vendor_item, preferred: false, vendor: create(:vendor))
      get :index
      response.body.must_include "+ 2 more"
    end
  end

  describe 'pagination' do
    before do
      sign_in create(:user)
    end

    it 'should paginate items by 10 per page' do
      create_list :item, 12
      get :index
      assigns[:items].count.must_equal 10
    end

    it 'should correctly load items on second  page' do
      create_list :item, 12
      get :index, page: 2
      assigns[:items].count.must_equal 2
    end
  end

  describe 'searching' do
    before do
      sign_in create(:user)
    end

    it 'should search items by number' do
      create :item, name: "Signing widget", number: 10001
      create :item, name: "Lovely widget", number: 23456
      xhr :get, :index, format: :json, page: 1, search: {all: "23"}
      assigns[:items].count.must_equal 1
    end

    it 'should search items by name' do
      create :item, name: "Signing widget"
      create :item, name: "Lovely widget"
      xhr :get, :index, format: :json, page: 1, search: {all: "sig"}
      assigns[:items].count.must_equal 1
    end

    it 'should search items by par_level' do
      create :item, number: 20001, name: "Signing widget", par_level: 10.0
      create :item, number: 20002, name: "Lovely widget", par_level: 23.54
      xhr :get, :index, format: :json, page: 1, search: {all: "10"}
      assigns[:items].count.must_equal 1
    end

    it 'should search items by vendor name' do
      i1 = create :item, name: "Signing widget"
      i1.vendors.first.update_attributes(name: "Hassel Delivery")
      i2 = create :item, name: "Lovely widget"
      i2.vendors.first.update_attributes(name: "Spencer Shipping Co.")
      xhr :get, :index, format: :json, page: 1, search: {all: "deliv"}
      assigns[:items].count.must_equal 1
    end
  end


  # PERMISSIONS:
  describe "agm" do
    let(:user){ create(:user, current_property_role: Role.agm) }
    let(:items){ create_list(:item, 4, property: user.properties.first) }

    before do
      sign_in user
    end


    describe "GET#index" do
      it 'displays, sorts, searches and filters all items' do
        items
        get :index
        items.each do |item|
          response.body.must_include item.name
        end
      end

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

      it "agm can see categories that he belongs to when looking at new_item form" do
        create_list(:category, 3)
        get :new
        assert_select "#item_category_ids option[value=?]", /.+/, count: 3 # should see all 3 categories
      end
    end

    describe "POST#create" do
      it "agm should have create access" do
        i, unit, vendor, category = build(:item), create(:unit), create(:vendor), create(:category)

        post :create, item: { name: i.name, unit_id: unit.id, price_unit_id: unit.id,
          inventory_unit_id: unit.id, category_ids: category.id, vendor_items_attributes: [{vendor_id: vendor.id}] }
        assert_redirected_to items_path
      end
    end

    describe "GET#edit" do
      it "agm should have edit access" do
        get :edit, id: items.first.id
        assert_response :success
      end

      it "agm can see categories that he belongs to when looking at edit_item form" do
        # 4 categories created with items
        get :edit, id: items.first.id
        assert_select "#item_category_ids option[value=?]", /.+/, count: 4 # should see all 4 categories
      end
    end

    describe "PUT#update" do
      it "agm should have put access" do
        items
        i, unit, vendor, category = build(:item), create(:unit), create(:vendor), create(:category)
        item = Item.last
        put :update, id: item.id, item: { name: i.name, unit_id: unit.id, price_unit_id: unit.id,
          inventory_unit_id: unit.id, category_ids: category.id, vendor_items_attributes: [{vendor_id: vendor.id}] }
        assert_redirected_to items_path
      end
    end

    describe "DELETE#destroy" do
      it 'destroys the item' do
        i = items.first
        delete :destroy, id: i.id
        assert_redirected_to items_path
      end
    end
  end

  describe "gm" do
    let(:user){ create(:user, current_property_role: Role.gm) }
    let(:items){ create_list(:item, 4, property: user.properties.first) }

    before do
      sign_in user
    end

    describe "GET#index" do
      it 'displays, sorts, searches and filters all items' do
        items
        get :index
        items.each do |item|
          response.body.must_include item.name
        end
      end

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

      it "gm can see categories that he belongs to when looking at new_item form" do
        create_list(:category, 3)
        get :new
        assert_select "#item_category_ids option[value=?]", /.+/, count: 3 # should see all 3 categories
      end
    end

    describe "POST#create" do
      it "gm should have create access" do
        i, unit, vendor, category = build(:item), create(:unit), create(:vendor), create(:category)

        post :create, item: { name: i.name, unit_id: unit.id, price_unit_id: unit.id,
          inventory_unit_id: unit.id, category_ids: category.id, vendor_items_attributes: [{vendor_id: vendor.id}] }
        assert_redirected_to items_path
      end
    end

    describe "GET#edit" do
      it "gm should have edit access" do
        get :edit, id: items.first.id
        assert_response :success
      end

      it "gm can see categories that he belongs to when looking at edit_item form" do
        # 4 categories created with items
        get :edit, id: items.first.id
        assert_select "#item_category_ids option[value=?]", /.+/, count: 4 # should see all 4 categories
      end
    end

    describe "PUT#update" do
      it "gm should have put access" do
        items
        i, unit, vendor, category = build(:item), create(:unit), create(:vendor), create(:category)
        item = Item.last
        put :update, id: item.id, item: { name: i.name, unit_id: unit.id, price_unit_id: unit.id,
          inventory_unit_id: unit.id, category_ids: category.id, vendor_items_attributes: [{vendor_id: vendor.id}] }
        assert_redirected_to items_path
      end
    end

    describe "DELETE#destroy" do
      it 'destroys the item' do
        i = items.first
        delete :destroy, id: i.id
        assert_redirected_to items_path
      end
    end
  end

  describe "manager" do
    let(:user){ create(:user, current_property_role: Role.manager) }
    let(:category1){ create(:category) }
    let(:category2){ create(:category) }
    let(:department1){ 
      dep = create(:department)
      dep.users << user
      dep.categories << category1
      dep
    }
    let(:managable_items) do
      items =[]; 2.times { i = create(:item); i.categories << category1; items << i }
      items
    end

    let(:non_managable_items) do 
      items =[]; 1.times { i = create(:item); i.categories << category2; items << i }
      items
    end

    before do
      sign_in user
    end

    describe "GET#index" do
      it "manager can see all items" do
        department1
        non_managable_items # call to let 'em be created
        managable_items     # call to let 'em be created
        get :index
        assert_select 'table.table tbody tr', 3
      end

      it "manager should have list access" do
        get :index
        assert_response :success
      end
    end

    describe "GET#new" do
      it "manager should have new access" do
        get :new
        assert_response :success
      end

      it "manager can see categories that he belongs to when looking at new_item form" do
        department1
        category1
        category2
        get :new
        assert_select "#item_category_ids option[value=?]", /.+/, count: 1 # should see only one category
        assert_select "form.locked", 0 # form should be unlocked
      end
    end

    describe "POST#create" do
      it "manager should have create access" do
        i, unit, vendor, category = build(:item), create(:unit), create(:vendor), create(:category)

        post :create, item: { name: i.name, unit_id: unit.id, price_unit_id: unit.id,
          inventory_unit_id: unit.id, category_ids: category.id, vendor_items_attributes: [{vendor_id: vendor.id}] }
        assert_redirected_to items_path
      end
    end

    describe "GET#edit" do
      it "manager should have edit access to items that related through departments" do
        department1
        get :edit, id: managable_items.first.id
        assert_response :success
      end

      it "manager should not have edit access to items that not related through departments" do
        department1
        get :edit, id: non_managable_items.first.id
        assert_select 'input[type="submit"]', 0
      end

      it "manager can see categories that he belongs to when looking at edit_item form" do
        department1
        category1
        category2
        get :edit, id: managable_items.first.id
        assert_select "#item_category_ids option[value=?]", /.+/, count: 1 # should see only one category
      end
    end

    describe "PUT#update" do
      it "manager should have update access to items that are related through departments" do
        department1
        i, unit, vendor, category = build(:item), create(:unit), create(:vendor), create(:category)
        put :update, id: managable_items.first.id, item: { name: i.name, unit_id: unit.id, price_unit_id: unit.id,
          inventory_unit_id: unit.id, category_ids: category.id, vendor_items_attributes: [{vendor_id: vendor.id}] }
        assert_redirected_to items_path
      end

      it "manager should not have update access to items that are not related through departments" do
        department1
        i, unit, vendor, category = build(:item), create(:unit), create(:vendor), create(:category)
        put :update, id: non_managable_items.first.id, item: { name: i.name, unit_id: unit.id, price_unit_id: unit.id,
          inventory_unit_id: unit.id, category_ids: category.id, vendor_items_attributes: [{vendor_id: vendor.id}] }
        assert_redirected_to authenticated_root_path
      end
    end

    describe "DELETE#destroy" do # should not have access to delete any items
      it "manager should not have delete access to items that are not related through departments" do
        department1
        delete :destroy, id: non_managable_items.first.id
        assert_redirected_to authenticated_root_path
      end

      it "manager should not have delete access to items that are related through departments" do
        department1
        i = managable_items.first
        delete :destroy, id: i.id
        assert_redirected_to authenticated_root_path
      end
    end
  end

  describe "corporate" do
    let(:user){ create(:user, current_property_role: Role.corporate) }
    let(:items){ create_list(:item, 3) }

    before do
      sign_in user
    end

    describe "GET#index" do
      it "corporate can see all items" do
        items
        get :index
        assert_select 'table.table tbody tr', 3
      end
    end

    describe "GET#new" do
      it "should not access new_item page" do
        get :new
        assert_redirected_to authenticated_root_path
      end
    end

    describe "POST#create" do
      it "should not access create action" do
        i, unit, vendor, category = build(:item), create(:unit), create(:vendor), create(:category)

        post :create, item: { name: i.name, unit_id: unit.id, price_unit_id: unit.id,
          inventory_unit_id: unit.id, category_ids: category.id, vendor_items_attributes: [{vendor_id: vendor.id}] }
        assert_redirected_to authenticated_root_path
      end
    end

    describe "GET#edit" do
      it "should not have access to edit page" do
        get :edit, id: items.first.id
        assert_response :success
        assert_select 'input[type="submit"]', 0
      end
    end

    describe "PUT#update" do
      it "should not have put access" do
        i, unit, vendor, category = build(:item), create(:unit), create(:vendor), create(:category)
        put :update, id: items.first.id, item: { name: i.name, unit_id: unit.id, price_unit_id: unit.id,
          inventory_unit_id: unit.id, category_ids: category.id, vendor_items_attributes: [{vendor_id: vendor.id}] }
        assert_redirected_to authenticated_root_path
      end
    end

    describe "DELETE#destroy" do
      it "should not have delete access" do
        delete :destroy, id: items.first.id
        assert_redirected_to authenticated_root_path
      end
    end
  end

end
