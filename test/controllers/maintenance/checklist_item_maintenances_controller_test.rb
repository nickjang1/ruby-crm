require 'minitest/autorun'
require 'test_helper'
describe Maintenance::ChecklistItemMaintenancesController do
  include Devise::TestHelpers
  
  # describe 'checklist items maintenances ' do
  #   before(:each) do
  #     @user = create(:user)
  #     property = create(:property)
  #     @cycle = create(:maintenance_cycle, year: Date.today.year, start_month: Date.today.month, cycle_type: 'room', property: property)
  #     property.switch!
  #     @maintainable = create(:maintenance_room)
  #     @maintenance_checklist_item = create(:maintenance_checklist_item)
  #     create_list(:maintenance_record, 1, property: property,user_id: @user.id,cycle_id: @cycle.id,status: "in_progress", maintainable_type: "Maintenance::Room",maintainable_id: @maintainable.id,started_at: Date.today)
  #   end
  #
  #   it 'create maintenance record' do
  #     post :create ,maintainable_type: "maintenance/room",id: @maintainable.id,checklist_item_maintenance: {}
  #     @record = @maintainable.maintenance_records.for_cycle(@cycle.id)
  #     checklist_item_miantenance = @record.checklist_item_maintenances.find_or_create_by(maintenance_checklist_item_id: @maintenance_checklist_item.id,status: Maintenance::ChecklistItemMaintenance::STATUS_NO_ISSUES.to_s,comment: "testing")
  #     assert_equal assigns[:checklist_item_maintenance].status,Maintenance::ChecklistItemMaintenance::STATUS_FIXED.to_s
  #   end
  # end
  
end
