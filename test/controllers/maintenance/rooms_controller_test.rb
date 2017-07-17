require 'minitest/autorun'
require 'test_helper'
describe Maintenance::RoomsController do
  include Devise::TestHelpers

  describe '#inspection' do
    before(:each) do
      @property = create(:property)
      @property.switch!
      @user = create(:user, current_property_role: Role.gm)
      @completed_rooms_count = 5
      @rooms = create_list(:maintenance_room, 10, property: @property)
      @cycle = create(:maintenance_cycle, user: @user, property: @property, start_month: Date.today.month - 1)
      @completed_rooms_count.times do |i|
        @records = create(:maintenance_record,
                          cycle: @cycle,
                          maintainable_id: @rooms[i].id,
                          maintainable_type: 'Maintenance::Room',
                          status: Maintenance::MaintenanceRecord::STATUS_FINISHED,
                          completed_on: (Date.today - 5.days))
      end

      create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Maintenance'))
      create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Inspection'))
      sign_in @user
    end

    it 'should return inspectable rooms' do
      get :inspection, format: :json
      response.status.must_equal 200
      result = JSON.parse(response.body)
      has_any_in_progress_status = result.map{ |r| r["status"] }.include?(Maintenance::MaintenanceRecord::STATUS_IN_PROGRESS)
      has_any_in_progress_status.must_equal false
    end

    it "should return rooms less than property's target inspection count" do
      @property.settings = { target_inspection_percent: 20 }
      @property.save

      get :inspection, format: :json
      result = JSON.parse(response.body)
      result.count.must_equal 2
      (result.count <= @property.target_inspection_count).must_equal true
    end

    it "should return shuffled completed rooms when property's target inspection count is less than completed rooms" do
      @property.settings = { target_inspection_percent: 20 }
      @property.save

      get :inspection, format: :json
      result1 = JSON.parse(response.body).map { |r| r['id'] }

      same = false
      5.times do |i|
        get :inspection, format: :json
        result2 = JSON.parse(response.body).map { |r| r['id'] }
        if result1 != result2
          same = true
          break
        end
      end

      assert same
    end
  end
end
