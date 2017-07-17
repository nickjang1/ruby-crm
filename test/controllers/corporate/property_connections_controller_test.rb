require 'minitest/autorun'
require 'test_helper'

describe Corporate::PropertyConnectionsController do
  include Devise::TestHelpers

  before do
    @user = create(:user)
    Property.current_id = nil
    @corporate  = create(:corporate, name: "CORP1")
    @corp_user  = create(:user, password: 'password', password_confirmation: 'password', corporate: @corporate, department_ids: [], current_property_role: nil)
    @property   = create(:property, name: 'PROPERTY1')
    @connection = create(:corporate_connection, corporate: @corporate, email: @corp_user.email, property: @property, created_by: @user)
    sign_in @corp_user
  end

  describe 'GET#show' do
    it 'should redirect back to settings if connection is "corporate_rejected"' do
      @connection.update_attributes(state: :corporate_rejected)
      get :show, id: @connection.id
      assert_redirected_to corporate_settings_path
    end

    it 'should redirect back to settings if connection is "property_rejected"' do
      @connection.update_attributes(state: :property_rejected)
      get :show, id: @connection.id
      assert_redirected_to corporate_settings_path
    end
  end
end
