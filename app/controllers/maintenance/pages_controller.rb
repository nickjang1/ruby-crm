class Maintenance::PagesController < Maintenance::BaseController
  def dashboard
    flash[:error] = "Cycle doesn't exist. Please create new cycle." unless current_cycle(:room) || current_cycle(:public_area)
  end
  
  def week_vs_completed_rooms_data
    @week_vs_room_data = {
      no_of_finished_rooms: [],
      weeks: [],   
      average: []
    }
    if Maintenance::Cycle.current
      start_month = Maintenance::Cycle.current.start_month
      maintenance_records = Maintenance::MaintenanceRecord.for_rooms.for_current_cycle
      records_groups = maintenance_records.finished.group_by_week(:started_at, last: 6).count
      records_count =  Maintenance::MaintenanceRecord.for_rooms.for_current_cycle.count
      average = records_count.zero? ? 0 : records_groups.values.sum / records_count
      records_groups.each do |record|
        if record[0].beginning_of_week.strftime("%m").to_i >= start_month
          @week_vs_room_data[:weeks] << l(record[0].beginning_of_week, format: :mini) + '-' + l(record[0].end_of_week, format: :mini)
          struct = {:y=>record[1],:color=>record[1] > average ? '#91c854' : '#ed5466'}
          @week_vs_room_data[:no_of_finished_rooms] << struct
        end
      end
      @week_vs_room_data[:average] << average
    end
    render json: @week_vs_room_data.to_json
  end

  def pm_room_progress_data
    @results = {
      label: 'Completed Rooms',
      color: '#00b1e1',
      data: []
    }

    @line = {
      label: 'Target Rooms to Maintain',
      color: '#aae16d'
    }

    current_cycle = Maintenance::Cycle.current
    start_date = Time.new(current_cycle.year, current_cycle.start_month)
    end_date = (start_date + (current_cycle.frequency_months - 1).months).end_of_month

    range = start_date..Time.current
    pm_records = Maintenance::MaintenanceRecord.for_rooms.for_current_cycle.finished
                                               .group_by_week(:completed_on, range: range)
                                               .count

    data = Array.new
    sum = 0
    week_number_of_cycle_start_date = start_date.strftime('%W').to_i

    pm_records.each do |date, count_of_processed|
      number_of_week = ((date - start_date) / 1.week).round + 1
      sum = sum + count_of_processed
      label = "#{number_of_week} Week"
      data << [label, sum]
    end

    @results[:data] = data
    number_of_rooms = Maintenance::Room.count
    total_weeks_in_cycle = end_date.strftime('%W').to_i - start_date.strftime('%W').to_i

    @line[:data] = (1..total_weeks_in_cycle).collect do |w|
      date = start_date + w.weeks
      label = "#{w} Week"
      [label, number_of_rooms]
    end

    render json: { xmax: total_weeks_in_cycle - 1, ymax: number_of_rooms, data: [@line, @results] }
  end
  
end
