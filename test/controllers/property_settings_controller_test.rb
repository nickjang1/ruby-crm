require 'minitest/autorun'
require 'test_helper'

describe PropertySettingsController do
  include Devise::TestHelpers

  describe "manager" do
    before do
      sign_in create(:user, current_property_role: Role.manager)
    end

    describe "GET#index" do
      it 'should not be able to see hotel settings' do
        get :index
        assert_redirected_to authenticated_root_path
      end
    end
  end

  describe "gm" do
    before do
      sign_in create(:user, current_property_role: Role.gm)
    end

    describe "GET#index" do
      it 'should be able to see hotel settings' do
        get :index
        assert_response :success
      end

      it 'should see "Connect to Corporate" button if no corporate connection exists' do
        get :index
        response.body.must_include "Connect to Corporate" 
      end

      it 'should not see "connect to Corporate" button if corporate connection exists' do
        property_id = Property.current_id
        Property.current_id = nil
        corporate = create(:corporate, name: "CORP1")
        corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
        Property.current_id = property_id
        create(:corporate_connection, corporate: corporate, property: Property.current, email: corp_user.email)
        get :index
        response.body.wont_include "Connect to Corporate"
      end
    end
  end

  describe "agm" do
    before do
      sign_in create(:user, current_property_role: Role.agm)
    end

    describe "GET#index" do
      it 'should not be able to see hotel settings' do
        get :index
        assert_redirected_to authenticated_root_path
      end
    end    
  end

  describe "corporate" do
    before do
      sign_in create(:user, current_property_role: Role.corporate)
    end

    describe "GET#index" do
      it 'should not be able to see hotel settings' do
        get :index
        assert_redirected_to authenticated_root_path
      end
    end
  end

end
