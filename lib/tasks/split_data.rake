namespace :data do
  desc 'split orders, requests and receipts'
  task split_data: :environment do |t, args|
    ActiveRecord::Base.transaction do
      Property.current_id = 14
      range = [4, 3, 4, 3, 3, 2]
      offset = 0
      range.each_with_index do |r, ri|
        PurchaseOrder.order(:id).limit(r).offset(offset).each_with_index do |order, oi|
          start_date = Time.current.beginning_of_year + ri.months + (oi*3 + 3).days
          order.created_at = start_date
          order.sent_at = start_date + oi.hours
          order.closed_at = order.sent_at + (oi * 10 + 10).minutes
          order.save!

          request = order.purchase_request
          request.created_at = start_date - (oi+1).hours
          request.approved_at = request.created_at + (oi+1) * 5.minutes

          request.save!

          prs = order.purchase_receipts
          prs.each_with_index do |receipt, pri|
            receipt.created_at = order.created_at + ((oi*10+10) / prs.count * (pri+1)).minutes
            receipt.save!

            irs = receipt.item_receipts
            irs.update_all created_at: receipt.created_at
          end
        end
        offset += r
      end
    end
  end

  desc 'split room maintenance records'
  task split_room_maintenance: :environment do
    ActiveRecord::Base.transaction do
      Property.current_id = 14

      # update maintenance data
      start_time = Time.current.beginning_of_year + 1.days

      Maintenance::Room.update_all created_at: start_time + 1.days
      Maintenance::ChecklistItem.where(public_area_id: nil).update_all created_at: start_time + 1.days
      puts "Updated Room --- #{start_time + 1.days}"

      Maintenance::PublicArea.update_all created_at: start_time + 1.days + 10.minutes
      Maintenance::ChecklistItem.for_public_areas.update_all created_at: start_time + 1.days + 10.minutes
      puts "Updated Public Areas --- #{start_time + 1.days + 10.minutes}"

      Maintenance::EquipmentType.update_all created_at: start_time + 1.days + 20.minutes
      Maintenance::Equipment.update_all created_at: start_time + 1.days + 30.minutes
      Maintenance::EquipmentChecklistItem.update_all created_at: start_time + 1.days + 40.minutes

      current_cycle = Maintenance::Cycle.current
      prev_cycle = current_cycle.dup
      prev_cycle.ordinality_number = 1
      prev_cycle.start_month -= prev_cycle.frequency_months
      prev_cycle.save!
      prev_cycle.reload
      puts prev_cycle.inspect
      Maintenance::Cycle.find_each do |cycle|
        cycle.created_at = Time.current.beginning_of_year + ((cycle.ordinality_number - 1) * cycle.frequency_months).months
        puts "Cycle created at - #{Time.current.beginning_of_year + ((cycle.ordinality_number - 1) * cycle.frequency_months).months}"
        cycle.save
      end

      # room maintenance data
      counts = [
          [10, 6, 6, 13],
          [12, 3, 9, 3],
          [4, 10, 7, 12],

          [14, 5, 7, 4],
          [6, 2, 9, 13],
          [10, 13, 12],
      ]
      offset = 0
      for month in counts[0..2]
        sum = month.reduce(&:+)
        records = current_cycle.maintenance_records.for_rooms.offset(offset).limit(sum).order(:maintainable_id)
        records.each do |record|
          new_record = record.dup
          new_record.cycle_id = prev_cycle.id
          new_record.save

          record.checklist_item_maintenances.each do |cim|
            new_cim = cim.dup
            new_cim.maintenance_record_id = new_record
            new_cim.save!
            new_cim.reload

            if cim.work_order
              new_wo = cim.work_order.dup
              new_wo.checklist_item_maintenance_id = new_cim.id
              new_wo.save!
            end
          end
        end
        puts "Found Records Count - #{records.count}"
        puts "Prev Cycle Record Count - #{prev_cycle.maintenance_records.count}"
        offset += sum
      end
      puts "Prev Cycle record count - #{prev_cycle.maintenance_records.count}"
      puts "current Cycle record count - #{current_cycle.maintenance_records.count}"

      offset = 0
      counts[0..2].each_with_index do |month, mi|
        month_start = Time.current.beginning_of_year + mi.months
        puts "Month Start - #{mi} - #{month_start}"
        month.each_with_index do |week, wi|
          week_start = month_start + wi.weeks
          puts "Week Start - #{wi} - #{week_start}"
          records = prev_cycle.maintenance_records.for_rooms.offset(offset).limit(week).order(:maintainable_id)
          records.to_a.each_with_index do |record, ri|
            record_start = week_start + 2.hours / week.to_f * ri.to_f
            puts "Record Start - #{record.id} - #{record_start}"
            record.created_at = record_start
            record.started_at = record_start
            record.completed_on = record_start + 10.minutes if record.status == 'finished'
            cim_count = record.checklist_item_maintenances.count
            record.checklist_item_maintenances.to_a.each_with_index do |cim, cii|
              cim_start = record_start + 1.hours / cim_count.to_f * cii
              cim.created_at = cim_start
              cim.save
              if cim.status == 'issues'
                cim_wo = cim.work_order
                cim_wo.created_at = cim_start + 1.minutes
                cim_wo.opened_at = cim_start + 1.minutes
                cim_wo.save
              end
            end
            record.save
          end
          offset += week
        end
      end
      offset = 0
      counts[3..5].each_with_index do |month, mi|
        month_start = Time.current.beginning_of_year + (mi + 3).months
        puts "Month Start - #{mi} - #{month_start}"
        month.each_with_index do |week, wi|
          week_start = month_start + wi.weeks
          puts "Week Start - #{wi} - #{week_start}"
          records = current_cycle.maintenance_records.for_rooms.offset(offset).limit(week).order(:maintainable_id)
          records.to_a.each_with_index do |record, ri|
            record_start = week_start + 2.hours / week.to_f * ri.to_f
            puts "Record Start - #{record.id} - #{record_start}"
            record.created_at = record_start
            record.started_at = record_start
            record.completed_on = record_start + 10.minutes if record.status == 'finished'
            cim_count = record.checklist_item_maintenances.count
            record.checklist_item_maintenances.to_a.each_with_index do |cim, cii|
              cim_start = record_start + 1.hours / cim_count.to_f * cii
              cim.created_at = cim_start
              cim.save
              if cim.status == 'issues'
                cim_wo = cim.work_order
                cim_wo.created_at = cim_start + 1.minutes
                cim_wo.opened_at = cim_start + 1.minutes
                cim_wo.save
              end
            end
            record.save
          end
          offset += week
        end
      end
    end
  end

  desc 'Create hotel and copy all data from hotel to other hotel'
  task :create_hotel_copy_data, [:hotel_name, :from_id, :email] => :environment do |t, args|
    ActiveRecord::Base.transaction do
      hotel = Property.create(name: args[:hotel_name])
      Property.current_id = hotel.id

      hotel_from = Property.find args[:from_id]
      duplicate_records Department.unscoped.where(property_id: hotel_from.id), hotel.id

      gm_user = User.find_by(email: args[:email])
      if gm_user
        gm_user.department_ids = hotel.departments.pluck(:id)
        gm_user.save
      else
        gm_user = FactoryGirl.create(:user, password: 'password', email: args[:email], department_ids: hotel.departments.pluck(:id))
        gm_user.confirm!
      end
      gm_user.current_property_role = Role.gm

      user = User.find_by(email: 'nikhilnatu@lodgistics.com')
      if user
        user.department_ids = [hotel.departments.find_by(name: 'Maintenance').id]
        user.save
      else
        user = FactoryGirl.create(:user, password: 'password', email: 'nikhilnatu@lodgistics.com', department_ids: [hotel.departments.find_by(name: 'Maintenance').id])
        user.confirm!
      end
      user.current_property_role = Role.manager

      # Property.current_id = hotel_from.id
      # puts 'Copying Items...'
      # item_mapping = {}
      # Item.find_each do |item|
      #   new_item = item.dup
      #   new_item.property_id = hotel.id
      #   new_item.created_at = item.created_at
      #   new_item.save(validate: false)
      #   item_mapping[item.id] = new_item.id
      # end
      #
      # puts 'Copying Tags...'
      # Tag.find_each do |tag|
      #   new_tag = tag.dup
      #   new_tag.property_id = hotel.id
      #   new_tag.created_at = tag.created_at
      #   tag.item_tags.each do |itag|
      #     new_itag = itag.dup
      #     new_itag.tag_id = new_tag.id
      #     new_itag.item_id = item_mapping[itag.item_id]
      #     new_itag.save
      #   end
      #   new_tag.save(validate: false)
      # end
    end
  end

  def duplicate_records(records, hotel_id)
    records.each do |record|
      new_record = record.dup
      new_record.property_id = hotel_id
      new_record.created_at = record.created_at
      new_record.save!
    end
  end
end
