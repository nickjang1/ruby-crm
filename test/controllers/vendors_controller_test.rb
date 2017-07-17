require 'test_helper'

describe VendorsController do
  include Devise::TestHelpers

  before do
    @user = create(:user)
    @vendor = create(:vendor, property: @user.all_properties.first)
    sign_in @user
  end

  it 'should remove items if vendor removed' do
    skip "Need to make sure that we really need to remove items if vendor removed"
    
    vendor_item = build(:vendor_item, vendor: @vendor)
    @item = create(:item, vendor_items: [vendor_item])

    delete :destroy, id: @vendor.id
    assert (not Item.exists?(@item)),
      "Item is destroyed when its last vendor is"
  end

  it 'should not remove items on vendor deletion if items has more vendors' do
    vendor_item = build(:vendor_item, vendor: @vendor)
    other_vendor_item = build(:vendor_item)
    @item = create(:item, vendor_items: [vendor_item, other_vendor_item])

    delete :destroy, id: @vendor.id
    assert Item.exists?(@item),
      "Item is not destroyed when it still has vendors"
  end

  describe "check permissions" do
    let(:corporate){ create(:user, current_property_role: Role.corporate) }
    let(:agm){ create(:user, current_property_role: Role.agm) }
    let(:gm){ create(:user, current_property_role: Role.gm) }
    let(:manager){ create(:user, current_property_role: Role.manager) }

    before do
      create_list(:vendor, 5, property: @user.all_properties.first)
    end

    describe "gm should have manage access" do
      before do
        sign_in gm
      end

      it "list access" do
        get :index
        assert_response :success
      end

      it "new access" do
        get :new
        assert_response :success
      end

      it "create access" do
        post :create, vendor: {name: "NEW VENDOR"}
        Vendor.last.name.must_equal "NEW VENDOR"
        assert_redirected_to vendors_path
      end

      it "edit access" do
        get :edit, id: Vendor.first.id
        assert_response :success
      end

      it "put access" do
        put :update, vendor: {name: "NEW"}, id: Vendor.first.id
        Vendor.first.name.must_equal "NEW"
        assert_redirected_to vendors_path
      end

      it "delete access" do
        delete :destroy, id: Vendor.first.id
        assert_redirected_to vendors_path
      end
    end

    describe "agm should have manage access" do
      before do
        sign_in agm
      end

      it "list access" do
        get :index
        assert_response :success
      end

      it "new access" do
        get :new
        assert_response :success
      end

      it "create access" do
        post :create, vendor: {name: "NEW VENDOR"}
        Vendor.last.name.must_equal "NEW VENDOR"
        assert_redirected_to vendors_path
      end

      it "edit access" do
        get :edit, id: Vendor.first.id
        assert_response :success
      end

      it "put access" do
        put :update, vendor: {name: "NEW"}, id: Vendor.first.id
        Vendor.first.name.must_equal "NEW"
        assert_redirected_to vendors_path
      end

      it "delete access" do
        delete :destroy, id: Vendor.first.id
        assert_redirected_to vendors_path
      end
    end

    describe "corporate should have only list access" do
      before do
        sign_in corporate
      end

      it "list access" do
        get :index
        assert_response :success
      end

      it "new access" do
        get :new
        assert_redirected_to authenticated_root_path
      end

      it "create access" do
        post :create, vendor: {name: "NEW VENDOR"}
        assert_redirected_to authenticated_root_path
      end

      it "edit access" do
        get :edit, id: Vendor.first.id
        assert_redirected_to authenticated_root_path
      end

      it "put access" do
        put :update, vendor: {name: "NEW"}, id: Vendor.first.id
        assert_redirected_to authenticated_root_path
      end

      it "delete access" do
        delete :destroy, id: Vendor.first.id
        assert_redirected_to authenticated_root_path
      end
    end

    describe "manager should have only list & show access" do
      before do
        sign_in manager
      end

      it "list access" do
        get :index
        assert_response :success
      end

      it "new access" do
        get :new
        assert_response :success
      end

      it "create access" do
        post :create, vendor: {name: "NEW VENDOR"}
        Vendor.last.name.must_equal "NEW VENDOR"
        assert_redirected_to vendors_path
      end

      it "edit access" do
        get :edit, id: Vendor.first.id
        assert_response :success
      end

      it "put access" do
        put :update, vendor: {name: "NEW"}, id: Vendor.first.id
        Vendor.first.name.must_equal "NEW"
        assert_redirected_to vendors_path
      end

      it "delete access" do
        delete :destroy, id: Vendor.first.id
        assert_redirected_to vendors_path
      end
    end
  end

  describe 'editing procurement_interface' do
    let(:vpt_attributes){ 
      {
        interface_type:  "vpt",
        data: {
          partner_id: "CFO124535X",
          username: "x-user-b3456",
          password: "password",
          division: "D145844",
          customer_number: "CO539PF94",
          department_number: "DEP543246",
          customer_group: "CG1"
        }
      }
    }
    let(:punch_out_attributes){
      {
        interface_type: "punchout",
        data: {
          password: "password",
          identity: "CFG334"
        }
      }
    }

    it "saves VPT -- USFOODS -- attributes" do
      assert_difference 'ProcurementInterface.count' do
        put :update, id: @vendor.id, vendor: { procurement_interface_attributes: vpt_attributes }
      end

      assert_equal vpt_attributes[:data], ProcurementInterface.last.data.symbolize_keys
    end

    it "saves punch out attributes" do
      assert_difference 'ProcurementInterface.count' do
        put :update, id: @vendor.id, vendor: { procurement_interface_attributes: punch_out_attributes }
      end

      assert_equal punch_out_attributes[:data], ProcurementInterface.last.data.symbolize_keys
    end
  end

end
