require 'minitest/autorun'
require 'test_helper'

describe Maintenance::PagesController do
  include Devise::TestHelpers

  describe 'GET#dashboard' do
    before do
      property = create(:property)
      create(:maintenance_cycle, year: Date.today.year, start_month: Date.today.month, cycle_type: 'room', property: property)
      create(:maintenance_cycle, year: Date.today.year, start_month: Date.today.month, cycle_type: 'public_area', property: property)
      property.switch!
    end

    it 'should not be able to access maintenance dashboard based on permissions' do
      user = create(:user, current_property_role: Role.gm)
      sign_in user
      get :dashboard
      assert_redirected_to :authenticated_root
    end

    it 'should be able to access maintenance dashboard based on permissions' do
      user = create(:user, current_property_role: Role.gm)
      create(:permission, role: Role.gm, department: user.departments.first, permission_attribute: attribute('Maintenance'))
      sign_in user
      get :dashboard
      assert_response :success
    end
  end
end
