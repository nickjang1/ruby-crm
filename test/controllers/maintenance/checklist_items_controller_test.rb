require 'minitest/autorun'
require 'test_helper'
describe Maintenance::ChecklistItemsController do
  include Devise::TestHelpers
  
  let(:user){ create(:user, current_property_role: Role.agm)} # user creates one department
  let(:property) { user.all_properties.first}
  let(:maintenance_checklist_items){ create_list(:maintenance_checklist_item, 4, property: property,user_id: user.id) }

  before(:each) do
    create(:permission, role: Role.agm, department: user.departments.first, permission_attribute: attribute('Maintenance'))
  end
  
  describe "index" do
    before do
      sign_in user
    end
    
    it 'should return checklist item' do
      get :index
      #assert assigns[:checklist_items].length.must_equal 4
      assert_response :success
    end
  end
  
  describe "create" do
    before(:each) do
      sign_in user
    end
    
    it "should create checklist item" do
      post :create, checklist_item: {user_id: user.id,name: "new checklist item",maintenance_type: "room"}
      assert_response :success
    end
  end
  
  describe "update" do
    before(:each) do
      @maintenance_checklist_item = create(:maintenance_checklist_item,user_id: user.id,property_id: property.id)
      sign_in user
    end
    
    it "should create checklist item" do
      put :update,id: @maintenance_checklist_item.id, checklist_item: {name: "updated checklist item name"}
      assert_equal assigns[:checklist_item].user_id,user.id
      assert_response :success
    end
  end
  
  
  
  describe 'DELETE#checklistitem' do
    before(:each) do
      @maintenance_checklist_item = create(:maintenance_checklist_item,user_id: user.id,property_id: property.id)
      sign_in user
    end
    
    it 'should update deleted field of checklist item' do
      delete :destroy,id: @maintenance_checklist_item.id   
      assert assigns[:checklist_item].is_deleted.must_equal true
      assert_response :success
    end
  end
  
end