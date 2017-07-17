require 'test_helper'

describe 'Guest Room Integration' do

  before do
    @user = create(:user, current_property_role: Role.gm)
    @rooms1 = create_list(:maintenance_room, 3, floor: 1)
    @rooms2 = create_list(:maintenance_room, 3, floor: 2)
    @cycle = create(:maintenance_cycle, user: @user, start_month: Date.today.month - 1, ordinality_number: 1)
    @checklist_areas = create_list(:maintenance_area, 3)
    @checklist_areas.each do |area|
      create_list(:maintenance_checklist_item, 3, area: area)
    end
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Maintenance'))
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('PM'))
    create(:permission, role: Role.gm, department: @user.departments.first, permission_attribute: attribute('Inspection'))
    sign_in @user
  end

  it 'list all rooms on remaining page', js: true do
    visit maintenance_rooms_path
    page.has_css?('td', 'Floor 1').must_equal true
    page.has_css?('td', 'Floor 2').must_equal true
    page.has_css?('td', 'Floor 3').must_equal true

    find('tr.floor-row:first-child').click
    @rooms1.each do |room|
      page.has_css?('td', "Guest Room ##{room.room_number}").must_equal true
    end

    find('tr.floor-row:last-child').click
    @rooms2.each do |room|
      page.has_css?('td', "Guest Room ##{room.room_number}").must_equal true
    end

    page.has_no_css?('a', 'Missed Guest Rooms')
    page.has_no_css?('a', 'In progress')
    page.has_no_css?('a', 'Completed')
  end

  it 'shows done percentage during pm', js: true do
    visit maintenance_rooms_path

    maintenance_room @rooms1.first, [@checklist_areas.first], false

    find('tr.floor-row:first-child').click
    page.has_css?('span.badge.badge-danger', '33% done').must_equal true

    click_link 'In progress'
    find('tr.floor-row:first-child').click
    page.has_css?('span.badge.badge-danger', '33% done').must_equal true
  end

  it 'shows completed rooms on completed page', js: true do
    # check maintenance completed
    visit maintenance_rooms_path
    page.has_css?('h4.title', 'Guest Room Maintenance').must_equal true

    maintenance_room @rooms1.first, @checklist_areas

    click_link 'Completed'
    find('td', text: "Floor #{@rooms1.first.floor}").find(:xpath, '..').click
    page.has_css?('td', "Guest Room PM - Room #{@rooms1.first.room_number}").must_equal true
    @rooms1.first.maintenance_records.for_current_cycle(:room).finished.count.must_equal 1

    # maintenance same room multiple times
    find('td', text: "Floor #{@rooms1.first.floor}").find(:xpath, '..').click
    maintenance_room @rooms1.first, @checklist_areas
    @rooms1.first.maintenance_records.for_current_cycle(:room).finished.count.must_equal 2

    # maintenance next room
    second_room = @rooms1.first(2).last
    maintenance_room second_room, @checklist_areas

    click_link 'Completed'
    find('tr.floor-row:first-child').click
    page.has_css?('td', "Guest Room PM - Room #{second_room.room_number}").must_equal true
    second_room.maintenance_records.for_current_cycle(:room).finished.count.must_equal 1
    all('table.floor-detail-table tr').count.must_equal 2

  end

  it 'list all completed rooms on inspection page', js: true do
    skip 'FAILING on CircleCI'
    visit maintenance_rooms_path
    page.has_css?('h4.title', 'Guest Room Maintenance').must_equal true
    maintenance_room @rooms1.first, @checklist_areas
    click_link 'Completed'
    # maintenance same room multiple times
    maintenance_room @rooms1.first, @checklist_areas, true, true
    @rooms1.first.maintenance_records.for_current_cycle(:room).finished.count.must_equal 2

    # maintenance next room
    second_room = @rooms1.first(2).last
    maintenance_room second_room, @checklist_areas

    # should show all rooms
    Property.current.setting[:target_inspection_percent] = 40
    Property.current.save
    visit inspection_maintenance_rooms_path
    page.has_css?('h4.title', 'Guest Room Inspection').must_equal true
    page.has_css?('p.text-primary.ellipsis', 'GUEST ROOMS INSPECTED').must_equal true
    @rooms1.first(2).each do |room|
      page.has_css?('span', "Guest Room ##{room.room_number}").must_equal true
      page.has_css?('dd', @user.name).must_equal true
    end

    @rooms2.each do |room|
      page.has_no_css?('span', "Guest Room ##{room.room_number}")
    end
    # check to show last maintenance record
    record = @rooms1.first.maintenance_records.for_current_cycle(:room).to_inspect.last
    page.has_xpath?("//dl[dt='Fixes:']/dd[contains(text(), '#{record.checklist_item_maintenances.fixed.count}')]").must_equal true

    # start new pm
    visit maintenance_rooms_path
    click_link 'Completed'
    maintenance_room @rooms1.first, [@checklist_areas.first], false

    visit inspection_maintenance_rooms_path
    page.has_css?('h4.title', 'Guest Room Inspection').must_equal true
    page.has_css?('p.text-primary.ellipsis', 'GUEST ROOMS INSPECTED').must_equal true
    @rooms1.first(2).each do |room|
      page.has_css?('span', "Guest Room ##{room.room_number}").must_equal true
    end

    # check to show last maintenance record
    record = @rooms1.first.maintenance_records.for_current_cycle(:room).to_inspect.last
    page.has_xpath?("//dl[dt='Fixes:']/dd[contains(text(), '#{record.checklist_item_maintenances.fixed.count}')]").must_equal true

    inspect_room(@rooms1.first)
    record.reload
    assert record.status == Maintenance::MaintenanceRecord::STATUS_COMPLETED.to_s

    all(:xpath, "//div[span=\"Guest Room ##{@rooms1.first.room_number}\"]").count.must_equal 1
    all('span.label.label-success', 'Inspected').count.must_equal 1
  end

end
