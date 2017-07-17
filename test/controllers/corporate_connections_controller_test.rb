require 'minitest/autorun'
require 'test_helper'

describe CorporateConnectionsController do
  include Devise::TestHelpers

  # PERMISSIONS:
  describe "agm" do
    before do
      sign_in create(:user, current_property_role: Role.agm)
    end

    describe "GET#new" do
      it "should not access new page" do
        get :new
        assert_redirected_to authenticated_root_path
      end
    end

    describe "GET#show" do
      it "should not access show page" do
        get :show
        assert_redirected_to authenticated_root_path
      end
    end
  end

  describe "gm" do
    before do
      sign_in create(:user, current_property_role: Role.gm)
    end

    describe "GET#new" do
      it "should not access new page" do
        get :new
        assert_response :success
      end
    end

    describe "GET#show" do
      it "should allow access show page" do
        property_id = Property.current_id
        Property.current_id = nil
        corporate = create(:corporate, name: "CORP1")
        corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
        Property.current_id = property_id
        create(:corporate_connection, corporate: corporate, property: Property.current, email: corp_user.email)
        get :show
        assert_response :success
      end

      it "should load editable connection" do
        property_id = Property.current_id
        Property.current_id = nil
        corporate = create(:corporate, name: "CORP1")
        corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
        Property.current_id = property_id
        con1 = create(:corporate_connection, corporate: corporate, property: Property.current, email: corp_user.email, state: :corporate_rejected)
        con2 = create(:corporate_connection, corporate: corporate, property: Property.current, email: corp_user.email)
        get :show
        assigns[:connection].must_equal con2
      end
    end
  end

  describe "manager" do
    before do
      sign_in create(:user, current_property_role: Role.manager)
    end

    describe "GET#new" do
      it "should not access new page" do
        get :new
        assert_redirected_to authenticated_root_path
      end
    end

    describe "GET#show" do
      it "should not access show page" do
        get :show
        assert_redirected_to authenticated_root_path
      end
    end
  end

  describe "corporate" do
    before do
      sign_in create(:user, current_property_role: Role.corporate)
    end

    describe "GET#new" do
      it "should not access new page" do
        get :new
        assert_redirected_to authenticated_root_path
      end
    end

    describe "GET#show" do
      it "should not access show page" do
        get :show
        assert_redirected_to authenticated_root_path
      end
    end
  end

end
