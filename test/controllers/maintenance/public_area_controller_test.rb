require 'minitest/autorun'
require 'test_helper'

describe Maintenance::PublicAreasController do
  include Devise::TestHelpers

  before do
    @cycle = create(:maintenance_cycle, cycle_type: 'public_area', property: Property.current, ordinality_number: 1)
    @user = create(:user)
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Maintenance'))
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('PM'))
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Inspection'))

    @public_areas = create_list(:maintenance_public_area, 5, property: Property.current)
    sign_in @user
  end

  describe 'pm' do
    it 'should list correct public areas' do
      get :index, format: :json, filter_type: 'remaining'
      areas = JSON.parse(response.body)
      areas.count.must_equal @public_areas.count

      get :index, format: :json, filter_type: 'in_progress'
      areas = JSON.parse(response.body)
      areas.count.must_equal 0

      get :index, format: :json, filter_type: 'completed'
      areas = JSON.parse(response.body)
      areas.count.must_equal 0

      in_progress = create(:maintenance_record, maintainable: @public_areas.first,
                           status: Maintenance::MaintenanceRecord::STATUS_IN_PROGRESS, cycle: @cycle)
      get :index, format: :json, filter_type: 'remaining'
      JSON.parse(response.body).count.must_equal @public_areas.count
      get :index, format: :json, filter_type: 'in_progress'
      JSON.parse(response.body).count.must_equal 1

      in_progress.status = Maintenance::MaintenanceRecord::STATUS_FINISHED
      in_progress.save
      get :index, format: :json, filter_type: 'in_progress'
      JSON.parse(response.body).count.must_equal 0
      get :index, format: :json, filter_type: 'completed'
      JSON.parse(response.body).count.must_equal 1
    end

    it 'should not list deleted public areas' do
      get :index, format: :json, filter_type: 'remaining'
      areas = JSON.parse(response.body)
      areas.count.must_equal @public_areas.count

      @public_areas.first.destroy
      get :index, format: :json, filter_type: 'remaining'
      JSON.parse(response.body).count.must_equal @public_areas.count - 1

      in_progress = create(:maintenance_record, maintainable: @public_areas.last,
                           status: Maintenance::MaintenanceRecord::STATUS_IN_PROGRESS, cycle: @cycle)
      get :index, format: :json, filter_type: 'in_progress'
      JSON.parse(response.body).count.must_equal 1

      @public_areas.last.destroy
      get :index, format: :json, filter_type: 'in_progress'
      JSON.parse(response.body).count.must_equal 0
    end
  end

  describe 'inspection' do
    it 'should list completed public areas' do
      get :inspection, format: :json
      JSON.parse(response.body).count.must_equal 0

      completed = create(:maintenance_record, maintainable: @public_areas.first, completed_on: Time.current,
                         status: Maintenance::MaintenanceRecord::STATUS_FINISHED, cycle: @cycle)
      get :inspection, format: :json
      JSON.parse(response.body).count.must_equal 1

      # for multiple pm
      create(:maintenance_record, maintainable: @public_areas.first, completed_on: Time.current,
             status: Maintenance::MaintenanceRecord::STATUS_FINISHED, cycle: @cycle)
      get :inspection, format: :json
      JSON.parse(response.body).count.must_equal 1
    end

    it 'should not list deleted public areas' do
      completed = create(:maintenance_record, maintainable: @public_areas.first, completed_on: Time.current,
                         status: Maintenance::MaintenanceRecord::STATUS_FINISHED, cycle: @cycle)
      get :inspection, format: :json
      JSON.parse(response.body).count.must_equal 1

      @public_areas.first.destroy
      get :inspection, format: :json
      JSON.parse(response.body).count.must_equal 0
    end
  end

end
