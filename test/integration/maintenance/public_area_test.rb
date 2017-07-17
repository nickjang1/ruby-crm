require 'test_helper'

describe 'Public Area Integration' do

  before do
    @user = create(:user, current_property_role: Role.gm)
    @cycle = create(:maintenance_cycle, user: @user, cycle_type: 'public_area', start_month: Date.today.month - 1, ordinality_number: 1)
    @public_areas = create_list(:maintenance_public_area, 3, user: @user)
    @public_areas.each do |area|
      @items = create_list(:maintenance_area, 3, maintenance_type: 'public_areas', public_area_id: area.id)
    end

    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Maintenance'))
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('PM'))
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Inspection'))
    sign_in @user
  end

  it 'should list all public areas on remaining page', js: true do
    visit maintenance_public_areas_path

    page.has_css?('td', 'Public Area 1').must_equal true
    page.has_css?('td', 'Public Area 2').must_equal true

    page.has_no_css?('a', 'Missed Areas')
    page.has_no_css?('a', 'In progress')
    page.has_no_css?('a', 'Completed')
  end

  it 'should show done percentage during pm', js: true do
    visit maintenance_public_areas_path

    maintenance_public_area @public_areas.first, [@public_areas.first.maintenance_checklist_items.first], false

    page.has_css?('span.badge.badge-danger', '33% done').must_equal true

    click_link 'In Progress'
    page.has_css?('span.badge.badge-danger', '33% done').must_equal true
  end

  it 'should show completed areas on completed page', js: true do
    # check maintenance completed
    visit maintenance_public_areas_path
    page.has_css?('h4.title', 'Public Area Selection').must_equal true

    first_area = @public_areas.first
    maintenance_public_area first_area, first_area.maintenance_checklist_items

    click_link 'Completed'
    page.has_css?('td', first_area.name).must_equal true
    first_area.maintenance_records.for_current_cycle(:public_area).finished.count.must_equal 1

    # maintenance same public area multiple times
    maintenance_public_area first_area, first_area.maintenance_checklist_items
    first_area.maintenance_records.for_current_cycle(:public_area).finished.count.must_equal 2

    # maintenance next public area
    second_area = @public_areas.first(2).last
    maintenance_public_area second_area, second_area.maintenance_checklist_items

    click_link 'Completed'
    page.has_css?('td', second_area.name).must_equal true
    second_area.maintenance_records.for_current_cycle(:public_area).finished.count.must_equal 1
    all('table#public-area-selection-table tr').count.must_equal 2
  end

  it 'should list all completed areas on inspection page', js: true do
    visit maintenance_public_areas_path
    page.has_css?('h4.title', 'Public Area Selection').must_equal true
    first_area = @public_areas.first
    maintenance_public_area first_area, first_area.maintenance_checklist_items
    click_link 'Completed'
    # maintenance same area multiple times
    maintenance_public_area first_area, first_area.maintenance_checklist_items, true, true
    first_area.maintenance_records.for_current_cycle(:public_area).finished.count.must_equal 2

    # maintenance next area
    second_area = @public_areas.first(2).last
    maintenance_public_area second_area, second_area.maintenance_checklist_items

    # should show all areas
    visit inspection_maintenance_public_areas_path
    page.has_css?('h4.title', 'Public Area Inspection').must_equal true
    page.has_css?('p.text-primary.ellipsis', 'PUBLIC AREAS INSPECTED').must_equal true
    @public_areas.first(2).each do |area|
      page.has_css?('span', area.name).must_equal true
      page.has_css?('dd', @user.name).must_equal true
    end

    third_area = @public_areas[2]
    page.has_no_css?('span', third_area.name)

    # check to show last maintenance record
    record = first_area.maintenance_records.for_current_cycle(:public_area).to_inspect.last
    page.has_xpath?("//dl[dt='Fixes:']/dd[contains(text(), '#{record.checklist_item_maintenances.fixed.count}')]").must_equal true

    # start new pm
    visit maintenance_public_areas_path
    click_link 'Completed'
    maintenance_public_area first_area, [first_area.maintenance_checklist_items.first], false

    visit inspection_maintenance_public_areas_path
    @public_areas.first(2).each do |area|
      page.has_css?('span', area.name).must_equal true
    end

    # check to show last maintenance record
    record = first_area.maintenance_records.for_current_cycle(:public_area).to_inspect.last
    page.has_xpath?("//dl[dt='Fixes:']/dd[contains(text(), '#{record.checklist_item_maintenances.fixed.count}')]").must_equal true

    inspect_public_area(first_area)
    record.reload
    assert record.status == Maintenance::MaintenanceRecord::STATUS_COMPLETED.to_s

    sleep 2

    # all(:xpath, "//div[span=\"Public Area #{first_area.id}\"]").count.must_equal 1
    all('span.label.label-success', 'Inspected').count.must_equal 1
  end

end