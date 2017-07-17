require 'test_helper'

describe DepartmentsController do
  include Devise::TestHelpers

  
  let(:user){ create(:user, current_property_role: Role.agm)} # user creates one department
  let(:property) { user.all_properties.first}
  let(:departments){ create_list(:department, 4, property: property) }
  let(:prop2){ create(:property, name: "Cool HOTEL") }

  before do
    sign_in user
  end

  describe '#index' do
    before do
      departments
      create_list(:department, 3, property: prop2)
      create(:permission, role: Role.agm, department: user.departments.first, permission_attribute: attribute('Team'))
    end

    it 'should list departments for the current property' do
      session[:property_id] = property.id
      get :index
      assigns['departments'].count.must_equal 5
    end
  end

  describe "check permissions" do
    let(:corporate){ create(:user, current_property_role: Role.corporate) }
    let(:agm){ create(:user, current_property_role: Role.agm) }
    let(:gm){ create(:user, current_property_role: Role.gm) }
    let(:manager){ create(:user, current_property_role: Role.manager) }

    before do
      # create_list(:department, 5, Property.accessible_by(user).first)
    end

    describe 'no permission, no access' do
      before do
        sign_in gm
      end

      it "list access" do
        get :index
        assert_redirected_to authenticated_root_path
      end

      it "new access" do
        get :new
        assert_redirected_to authenticated_root_path
      end

      it "create access" do
        post :create, department: {name: "NEW VENDOR"}
        assert_redirected_to authenticated_root_path
      end

      it "edit access" do
        get :edit, id: Department.first.id
        assert_redirected_to authenticated_root_path
      end

      it "put access" do
        put :update, department: {name: "NEW"}, id: Department.first.id
        assert_redirected_to authenticated_root_path
      end

      it "delete access" do
        delete :destroy, id: Department.first.id
        assert_redirected_to authenticated_root_path
      end
    end

    describe "agm should have manage access" do
      before do
        sign_in gm
        create(:permission, role: Role.gm, department: gm.departments.first, permission_attribute: attribute('Team'))
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
        post :create, department: {name: "NEW VENDOR"}
        Department.last.name.must_equal "NEW VENDOR"
        assert_redirected_to departments_path
      end

      it "edit access" do
        get :edit, id: Department.first.id
        assert_response :success
      end

      it "put access" do
        put :update, department: {name: "NEW"}, id: Department.first.id
        Department.first.name.must_equal "NEW"
        assert_redirected_to departments_path
      end

      it "delete access" do
        delete :destroy, id: Department.first.id
        assert_redirected_to departments_path
      end
    end

    # describe "corporate should have only list access" do
    #   before do
    #     sign_in corporate
    #   end
    #
    #   it "list access" do
    #     get :index
    #     assert_response :success
    #   end
    #
    #   it "new access" do
    #     get :new
    #     assert_redirected_to authenticated_root_path
    #   end
    #
    #   it "create access" do
    #     post :create, department: {name: "NEW VENDOR"}
    #     assert_redirected_to authenticated_root_path
    #   end
    #
    #   it "edit access" do
    #     get :edit, id: Department.first.id
    #     assert_redirected_to authenticated_root_path
    #   end
    #
    #   it "put access" do
    #     put :update, department: {name: "NEW"}, id: Department.first.id
    #     assert_redirected_to authenticated_root_path
    #   end
    #
    #   it "delete access" do
    #     delete :destroy, id: Department.first.id
    #     assert_redirected_to authenticated_root_path
    #   end
    # end

    # describe "manager should have only list & show access" do
    #   before do
    #     sign_in manager
    #   end
    #
    #   it "list access" do
    #     get :index
    #     assert_response :success
    #   end
    #
    #   it "new access" do
    #     get :new
    #     assert_redirected_to authenticated_root_path
    #   end
    #
    #   it "create access" do
    #     post :create, department: {name: "NEW VENDOR"}
    #     assert_redirected_to authenticated_root_path
    #   end
    #
    #   it "edit access" do
    #     get :edit, id: Department.first.id
    #     assert_response :success
    #   end
    #
    #   it "put access" do
    #     put :update, department: {name: "NEW"}, id: Department.first.id
    #     assert_redirected_to authenticated_root_path
    #   end
    #
    #   it "delete access" do
    #     delete :destroy, id: Department.first.id
    #     assert_redirected_to authenticated_root_path
    #   end
    # end
  end

end
