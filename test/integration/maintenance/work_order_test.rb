require 'test_helper'

describe 'Guest Room Integration' do

  before do
    @user = create(:user, current_property_role: Role.gm)
    @cycle = create(:maintenance_cycle, user: @user, start_month: Date.today.month - 1, ordinality_number: 1)
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Maintenance'))
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Work Orders'))
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('WO Listing'), options: [:all])
    sign_in @user
  end

  describe 'Count of WOs in all types of grouping' do
    it 'should be equal', js: true do
      users = create_list(:user, 5, current_property_role: Role.gm)
      deleted_user = users.last
      deleted_user.deleted_at = Time.now
      deleted_user.save
      work_orders = create_list(:maintenance_work_order, 10, status: :open, priority: :h, created_by: users.sample, opened_at: Time.now)
      @user.settings = {work_order_group_by: 'priority'}
      @user.save
      visit maintenance_work_orders_path
      grouped1_work_order_tabs = all('#group-options li>a>.badge')
      group1_count = 0
      grouped1_work_order_tabs.each do |tab|
        group1_count += tab.text.to_i
      end

      @user.settings = {work_order_group_by: 'created_by'}
      @user.save
      visit maintenance_work_orders_path
      grouped2_work_order_tabs = all('#group-options li>a>.badge')
      group2_count = 0
      grouped2_work_order_tabs.each do |tab|
        group2_count += tab.text.to_i
      end
      group1_count.must_equal group2_count
    end
  end

  it 'should save wo group by filter when the user change group by filter' do
    visit maintenance_work_orders_path
    filters = I18n.t('maintenance.work_orders.index.grouping_options').invert.keys
    random_filter = filters.sample(1)[0]
    select random_filter, from: 'wo-grouping'
    visit maintenance_work_orders_path
    page.has_css?('#wo-grouping', random_filter).must_equal true
  end
end
