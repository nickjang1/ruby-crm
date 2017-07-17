module MaintenanceMacros

  def maintenance_room(room, checklist_areas, complete = true, work_order = false)
    find('td', text: "Floor #{room.floor}").find(:xpath, '..').click
    find(:xpath, "//td[not(details) and contains(text(), \"Guest Room ##{room.room_number}\")]").find(:xpath, '..').find('a.start-maintenance').click

    slug = "floor#{room.floor}-room#{room.room_number}"
    page.has_css?('h4.title', "Guest Room PM - Room #{room.room_number}").must_equal true
    assert current_path == maintenance_room_path(slug)

    checklist_areas.each do |area|
      area.checklist_items.each do |item|
        page.has_css?('span', item.name).must_equal true
        if work_order
          find("tr[data-item-id=\"#{item.id}\"] a.room-checklist-action.issue-fixed.inactive").click
          page.has_css?('h4.text-primary', 'What did you fix?')
          fill_in 'maintenance-comment', with: "Fixed for Room #{room.room_number}"
          click_button 'Mark Fixed'
          sleep 0.5
        else
          find("tr[data-item-id=\"#{item.id}\"] a.room-checklist-action.no-issues.inactive").click
          sleep 0.5
        end
      end
    end

    if complete
      page.has_css?('h4.text-primary', 'Maintenance Completed').must_equal true
      click_button 'OK'
    else
      find_link_with_icon('btn-primary', 'ico-clock', 'Continue Later').click
      find('a.btn-danger.confirm', text: "YES I'm sure!").click
    end

    page.has_css?('h4.title', 'Guest Room Maintenance').must_equal true
    assert current_path == maintenance_rooms_path
  end

  def inspect_room(room)
    find(:xpath, "//div[contains(@class, 'room-name') and span='Guest Room ##{room.room_number}']/./following-sibling::div").find('a.start-maintenance').click
    find_link_with_icon('btn-primary', 'ico-stack-checkmark', 'Complete').click
    find('a.btn-danger.confirm', text: "YES I'm sure!").click

    page.has_css?('h4.title', 'Guest Room Inspection')
    assert current_path == inspection_maintenance_rooms_path
  end

  def maintenance_public_area(public_area, checklist_items, complete = true, work_order = false)
    find(:xpath, "//td[not(details) and contains(text(), \"#{public_area.name}\")]").find(:xpath, '..').find('a.start-maintenance').click

    slug = public_area.name.split(' ').join('_')
    page.has_css?('h4.title', public_area.name).must_equal true

    assert current_path == maintenance_public_area_path(slug)

    checklist_items.each do |item|
      page.has_css?('span', item.name).must_equal true
      if work_order
        find("tr[data-item-id=\"#{item.id}\"] a.room-checklist-action.issue-fixed.inactive").click
        page.has_css?('h4.text-primary', 'What did you fix?')
        fill_in 'maintenance-comment', with: "Fixed for Public Area #{public_area.name}"
        click_button 'Mark Fixed'
        sleep 0.5
      else
        find("tr[data-item-id=\"#{item.id}\"] a.room-checklist-action.no-issues.inactive").click
        sleep 0.5
      end
    end

    if complete
      page.has_css?('h4.text-primary', 'Maintenance Completed').must_equal true
      click_button 'OK'
    else
      find_link_with_icon('btn-primary', 'ico-clock', 'Continue Later').click
      find('a.btn-danger.confirm', text: "YES I'm sure!").click
    end

    page.has_css?('h4.title', 'Public Area Selection').must_equal true
    assert current_path == maintenance_public_areas_path
  end

  def inspect_public_area(public_area)
    find(:xpath, "//div[contains(@class, 'public-area-name') and span='#{public_area.name}']/./following-sibling::div").find('a.start-maintenance').click
    find_link_with_icon('btn-primary', 'ico-stack-checkmark', 'Complete').click
    find('a.btn-danger.confirm', text: "YES I'm sure!").click

    page.has_css?('h4.title', 'Public Area Inspection')
    assert current_path == inspection_maintenance_public_areas_path
  end

end