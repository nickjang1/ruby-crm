require 'test_helper'

describe 'Access Policy' do

  describe 'for GM' do
    before(:each) do
      @gm = create(:user, current_property_role: Role.gm)
    end

    it 'settings?' do
      permit!(@gm, :access, :settings?)
    end
  end

  describe 'for Admin' do
    before(:each) do
      @gm = create(:user, current_property_role: Role.gm)
    end

    it 'settings?' do
      permit!(@gm, :access, :settings?)
    end
  end

  describe 'all permissions' do
    it 'procurement?' do
      check_permission(:access, :procurement?, 'Procurement')
    end

    it 'work_order?' do
      check_permission(:access, :work_order?, 'Work Orders')
    end

    it 'pm?' do
      check_permission(:access, :pm?, 'PM')
    end

    it 'pm_setup?' do
      check_permission(:access, :pm_setup?, 'PM Setup')
    end

    it 'inspection?' do
      check_permission(:access, :inspection?, 'Inspection')
    end
  end

end

