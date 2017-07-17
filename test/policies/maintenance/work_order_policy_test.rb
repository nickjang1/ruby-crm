require 'test_helper'

describe 'Work Order Policy' do

  describe 'index?' do
    before(:each) do
      @gm = create(:user, current_property_role: Role.gm)
      @department = create(:department)
    end

    it 'denies access if no permission' do
      forbid!(@gm, Maintenance::WorkOrder, :index?)
      @gm.departments << @department
      @gm.save
      forbid!(@gm, Maintenance::WorkOrder, :index?)
    end

    it 'denies access if no options' do
      permission = create(:permission, department: @department, role: Role.gm, permission_attribute: attribute('WO Listing'))
      forbid!(@gm, Maintenance::WorkOrder, :index?)
    end

    it 'allows access if any options' do
      permission = create(:permission, department: @department, role: Role.gm, permission_attribute: attribute('WO Listing'))
      permission.options = [:all]
      permission.save
      permit!(@gm, Maintenance::WorkOrder, :index?)
    end

    it 'denies access for different department' do
      permission = create(:permission, department: @department, role: Role.gm, permission_attribute: attribute('WO Listing'))
      permission.options = []
      permission.save
      new_department = create(:department)
      new_permission = create(:permission, department: new_department, role: Role.gm, permission_attribute: attribute('WO Listing'))
      @gm.departments.destroy_all
      @gm.departments << new_department
      @gm.save
      forbid!(@gm, Maintenance::WorkOrder, :index?)

      new_permission.options = [:all]
      new_permission.save
      permit!(@gm, Maintenance::WorkOrder, :index?)
    end

    it 'denise access for different role' do
      new_department = create(:department)
      new_permission = create(:permission, department: new_department, role: Role.gm, permission_attribute: attribute('WO Listing'))
      agm = create(:user, current_property_role: Role.agm)
      agm.departments << new_department
      agm.save
      forbid!(agm, Maintenance::WorkOrder, :index?)
      new_permission.role = Role.agm
      new_permission.save
      forbid!(@gm, Maintenance::WorkOrder, :index?)
      permit!(agm, Maintenance::WorkOrder, :index?)
    end
  end

  it 'create?' do
    check_permission Maintenance::WorkOrder, :create?, 'Create WOs'
  end

  it 'edit?' do
    check_permission Maintenance::WorkOrder, :edit?, 'Edit WO'
  end

  describe 'permitted_attributes' do
    before(:each) do
      @gm = create(:user, current_property_role: Role.gm)
      @department = create(:department)
      @work_order = create(:maintenance_work_order)
      create(:permission, department: @department, role: Role.gm, permission_attribute: attribute('Maintenance'))
      create(:permission, department: @department, role: Role.gm, permission_attribute: attribute('Work Orders'))
      @gm.departments << @department
      @gm.save
    end

    it 'should have only permitted attributes' do
      permission = build(:permission, department: @department, role: Role.gm, permission_attribute: attribute('Edit WO'))
      permission.options = [:status]
      permission.save
      permit_attributes!(@gm, @work_order, [:status])
      forbid_attributes!(@gm, @work_order, [:status, :priority])
    end

    it 'should have merged attributes by departments' do
      permission = build(:permission, department: @department, role: Role.gm, permission_attribute: attribute('Edit WO'))
      permission.options = [:status]
      permission.save
      new_department = create(:department)
      new_permission = build(:permission, department: new_department, role: Role.gm, permission_attribute: attribute('Edit WO'))
      @gm.departments << new_department
      @gm.save
      permit_attributes!(@gm, @work_order, [:status])
      forbid_attributes!(@gm, @work_order, [:status, :priority])

      new_permission.options = [:priority]
      new_permission.save
      permit_attributes!(@gm, @work_order, [:status, :priority])
    end

    it 'should have permitted attributes by roles' do
      new_department = create(:department)
      new_permission = build(:permission, department: new_department, role: Role.gm, permission_attribute: attribute('Edit WO'))
      new_permission.options = [:priority]
      new_permission.save
      agm = create(:user, current_property_role: Role.agm)
      agm.departments << new_department
      agm.save
      forbid_attributes!(agm, @work_order, [:status])
      new_permission.role = Role.agm
      new_permission.save
      permit_attributes!(agm, @work_order, [:priority])
      forbid_attributes!(@gm, @work_order, [:priority])
    end
  end

  describe 'scopes' do
    before(:each) do
      @gm = create(:user, current_property_role: Role.gm)
      @agm = create(:user, current_property_role: Role.agm)
      @manager = create(:user, current_property_role: Role.manager)
      @department = create(:department)
      @gm.departments << @department
      @gm.save
      @agm.departments << @department
      @agm.save
      @manager.departments << @department
      @manager.save
      @work_order1 = create(:maintenance_work_order, opened_by: @gm)
      @work_order2 = create(:maintenance_work_order, assigned_to: @gm)
      @work_order3 = create(:maintenance_work_order)
    end

    it 'should have correct scopes with permission options' do
      permission = create(:permission, department: @department, role: Role.gm, permission_attribute: attribute('WO Listing'))
      forbid_scope!(@gm, Maintenance::WorkOrder, [@work_order1, @work_order2, @work_order3])
      forbid_scope!(@agm, Maintenance::WorkOrder, [@work_order1, @work_order2, @work_order3])
      forbid_scope!(@manager, Maintenance::WorkOrder, [@work_order1, @work_order2, @work_order3])
      permission.options = [:all]
      permission.save
      permit_scope!(@gm, Maintenance::WorkOrder, [@work_order1, @work_order2, @work_order3])
      permission.options = [:own]
      permission.save
      permit_scope!(@gm, Maintenance::WorkOrder, [@work_order1])
      forbid_scope!(@gm, Maintenance::WorkOrder, [@work_order2])
      forbid_scope!(@gm, Maintenance::WorkOrder, [@work_order3])
      permission.options = [:assigned_to]
      permission.save
      permit_scope!(@gm, Maintenance::WorkOrder, [@work_order2])
      forbid_scope!(@gm, Maintenance::WorkOrder, [@work_order1])
      forbid_scope!(@gm, Maintenance::WorkOrder, [@work_order3])
    end

    it 'should have correct scopes with roles' do
      permission = create(:permission, department: @department, role: Role.gm, permission_attribute: attribute('WO Listing'))
      permission.options = [:assigned_to]
      permission.role = Role.agm
      permission.save
      @work_order2.assigned_to = @agm
      @work_order2.save
      permit_scope!(@agm, Maintenance::WorkOrder, [@work_order2])
      forbid_scope!(@agm, Maintenance::WorkOrder, [@work_order1])
      forbid_scope!(@agm, Maintenance::WorkOrder, [@work_order3])
      forbid_scope!(@gm, Maintenance::WorkOrder, [@work_order1, @work_order2, @work_order3])
    end
  end

end