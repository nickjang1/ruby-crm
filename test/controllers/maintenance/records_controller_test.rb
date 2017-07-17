require 'minitest/autorun'
require 'test_helper'
describe Maintenance::RecordsController do
  include Devise::TestHelpers

  describe 'Maintenance Records Updating finishing status' do
    before(:each) do
      property = create(:property)
      property.switch!
      @user = create(:user, current_property_role: Role.gm)
      @room = create(:maintenance_room, property: property)
      @record = create(:maintenance_record, maintainable_id: @room.id, maintainable_type: 'Maintenance::Room', status: Maintenance::MaintenanceRecord::STATUS_IN_PROGRESS, started_at: (Date.today - 5.days))
      create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Maintenance'))
      sign_in @user
    end

    it 'should update maintenance record completed_by and status fields' do
      put :update,id: @record.id, maintenance_maintenance_record: { completed_by_id: @user.id, status: Maintenance::MaintenanceRecord::STATUS_FINISHED }
      assert_redirected_to maintenance_rooms_path
      assert_equal assigns[:record].completed_by, @user
      assert_equal assigns[:record].status.to_sym, Maintenance::MaintenanceRecord::STATUS_FINISHED
    end
  end

end
