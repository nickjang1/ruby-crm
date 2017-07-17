class ReportsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_date_range, except: [:index, :favorites, :favorite, :show, :trending_cloud]
  around_filter :action_with_property, except: [:index, :favorites, :favorite, :show]
  add_breadcrumb I18n.t("controllers.reports.reports"), :reports_path
  respond_to :html, :pdf
  layout false, except: [:index, :favorites, :favorite, :show]
  include MaintenanceHelper
  include ApplicationHelper

  def favorites
    authorize Report.new, :index?
    add_breadcrumb t("controllers.reports.favorites")
    @title = t("controllers.reports.favorite_reports")
    @reports = current_user.favorite_reports.for_maintenance
    render :index
  end

  def index
    authorize Report.new
    @title = t("controllers.reports.reports_listing")
    @reports = Report.for_maintenance
    # @reports = @reports.for_maintenance if current_user.frontdesk_department?
  end

  def favorite
    @report = Report.find(params[:id])
    @report.toggle_favorited_by!(current_user)
    render json: true
  end

  def show
    @report = Report.find_by(permalink: params[:id])
    @report.record_run_by!(current_user)
    add_breadcrumb @report.name
    render :show
  end

  def item_price_variance
    respond_to do |format|
      format.html
      format.json do
        results = []
        Item.all.each do |item|
          ipv = ItemPriceVariance.new(item, @from..@to)
          row = {}
          row[:item_id]  = item.id
          row[:vendor]   = item.vendor_ids.first
          row[:category] = item.category_ids.first
          row[:lists]    = item.list_ids.join(',')
          row[:item_name] = item.name
          row[:num_orders] = ipv.num_orders
          next if row[:num_orders] == 0
          row[:average_price] = ipv.average_price
          row[:average_variance] = ipv.average_variance
          row[:increase] = ipv.increase
          next if row[:average_variance] == '0' && row[:increase] == '0'
          results << row
        end

        render json: results
      end
    end
  end

  def vendor_spend
    respond_to do |format|
      format.html
      format.json do
        total_spend = PurchaseReceipt.where(created_at: @from..@to).map(&:total_w_freight).reduce(&:+)
        result = []

        Vendor.all.each do |vendor|
          row = {vendor_name: vendor.name }
          receipts = vendor.purchase_receipts.where(created_at: @from..@to)
          row[:num_orders] = receipts.map(&:purchase_order_id).uniq.count
          spend = receipts.map(&:total_w_freight).reduce(&:+)

          next unless spend
          row[:spend] = spend.to_s
          row[:percentage_of_spend] = spend ? spend / total_spend * 100 : 0
          result << row
        end

        render json: result.to_json
      end
    end
  end

  ### ITEM CONSUMED REPORT ========>

  def items_consumption
    respond_to do |format|
      format.html
      format.json do
        result = []
        months_count_in_the_range = ((@to - @from).to_f / (24 *60 *60) / 30.44).round # 30.44 avg days number in month

        Item.where(created_at: @from..@to).includes(:purchase_orders, :vendors).load.each do |item|
          row    = {name: item.name}
          orders = item.purchase_orders.joins(:purchase_receipts).where(created_at: @from..@to).uniq
          next unless orders.any?
          row[:item_id]  = item.id
          row[:vendor]   = item.vendors.first.name
          row[:category] = item.categories.first.name
          row[:lists]    = item.lists.pluck(:name).join(',')
          row[:last_inventory_time] = item.purchase_requests.where(created_at: @from..@to).order(created_at: :desc).limit(1).first.try(:created_at)
          row[:avg_monthly_orders]  = (orders.count.to_f / months_count_in_the_range * 100).round / 100.0
          item_receipts             = item.item_receipts.where(created_at: @from..@to)
          row[:avg_order_qty]  = "#{ (item_receipts.sum(:quantity) / orders.count.to_f * 100).round / 100.0 } <br><span class='text-muted semibold'>#{ item.unit.name }</span>"
          row[:avg_order_cost] = item_receipts.any? ? "#{I18n.t :currency}#{ (item_receipts.map(&:total).map(&:to_f).inject(&:+) / orders.count.to_f * 100).round / 100.0 }" : ""

          result << row
        end
        render json: result.to_json
      end
    end
  end

  def item_orders_chart_data
    # @to - @from <-- current period selected, for the chart we need to consider it and 5 periods (of the same size) before
    result = []
    item = Item.find(params[:id])
    months_count_in_the_range = ((@to - @from).to_f / (24 *60 *60) / 30.44).round # 30.44 avg days number in month
    periods_count = {3 => 5, 6 => 3, 12 => 2}[months_count_in_the_range]

    chart_data_start = @from - (months_count_in_the_range * periods_count).month
    chart_date_check_point = chart_data_start
    while(chart_date_check_point < @to)
      orders = item.purchase_orders.joins(:purchase_receipts).where(created_at: chart_date_check_point..chart_date_check_point + months_count_in_the_range.month)
      result << [chart_date_check_point, orders.count]
      chart_date_check_point += months_count_in_the_range.month
    end
    render json: result.to_json
  end

  ### <======== ITEM CONSUMED REPORT

  def category_spend
    respond_to do |format|
      format.html
      format.json do
        total_spend = PurchaseReceipt.where(created_at: @from..@to).map(&:total_w_freight).reduce(&:+)
        result = []

        Category.includes(:items).load.each do |category|
          item_ids = category.item_ids
          next if item_ids.count == 0
          row = {category_name: category.name }
          receipts = PurchaseReceipt.include_items(item_ids).where(created_at: @from..@to)
          row[:num_orders] = receipts.map(&:purchase_order_id).uniq.count
          spend = receipts.map { |receipt| receipt.total(item_ids) }.reduce(&:+)

          next unless spend
          row[:spend] = spend.to_s
          row[:percentage_of_spend] = spend / total_spend * 100
          result << row
        end

        render json: result.to_json
      end
    end
  end

  def items_spend
    respond_to do |format|
      format.html
      format.json do
        total_spend = PurchaseReceipt.where(created_at: @from..@to).map(&:total_w_freight).reduce(&:+)
        result = []

        Item.all.each do |item|
          row = {name: item.name }
          receipts = PurchaseReceipt.include_items([item.id]).where(created_at: @from..@to)
          row[:num_orders] = receipts.map(&:purchase_order_id).uniq.count
          spend = receipts.map { |receipt| receipt.total([item.id]) }.reduce(&:+)
          next unless spend
          row[:spend] = spend.to_s
          row[:percentage_of_spend] = spend * 100 / total_spend
          result << row
        end
        render json: result.to_json
      end
    end
  end

  def inventory_vs_ordering
    respond_to do |format|
      format.html
      format.json do
        results = []
        Item.all.each do |item|
          ivo = InventoryVsOrdering.new(item, @from..@to)
          row = {}
          row[:item_id]  = item.id
          row[:locations] = item.location_ids.join(',')
          row[:category] = item.category_ids.first
          row[:lists]  = item.list_ids.join(',')
          row[:item_name] = item.name
          row[:avg_orders] = ivo.average_orders
          row[:avg_counts] = ivo.average_counts
          next if row[:avg_orders] == '0.00' and row[:avg_counts] == '0.00'
          row[:last_count_at] = ivo.last_count_at
          row[:last_order_at] = ivo.last_order_at

          results << row
        end

        render json: results
      end
    end
  end

  def maintenance_work_orders
    unless request.format.html?
      @results = Maintenance::WorkOrder.all.order_by_priority
      if params[:date_range].present?
        @results = @results.where(created_at: @from..@to)
                    .includes([:opened_by, :closed_by, :maintainable, :assigned_to, :material_items,
                               materials: [:item],
                               checklist_item_maintenance: [:maintenance_checklist_item]
                              ])
      end

      @results = @results.map do |wo|
        data = {
          id: wo.id,
          description: wo.description,
          priority: t("reports.work_order_trendings.priority.#{wo.priority}"),
          opened_by_name: wo.opened_by.name,
          location_name: wo.location_name,
          status: work_order_status_labels[wo.status.to_sym],
          type: wo.maintainable_type,
          priority_value: wo.priority,
          days_opened: wo.days_opened,
          is_unassigned: wo.assigned_to_id == Maintenance::WorkOrder::UNASSIGNED,
          assigned_to_name: work_order_assigned_to(wo),
          materials_exists: wo.materials.count > 0,
          material_items: wo.materials.map do |m|
            {
              quantity: quantity_format(m.quantity),
              unit: m.item.inventory_unit.name,
              name: m.item.name
            }
          end,
          materials_cost: humanized_currency_format(wo.material_total),
          detail_exists: wo.materials.count > 0 || wo.closing_comment.present? || wo.duration.present?
        }
        if wo.status == Maintenance::WorkOrder::STATUS_CLOSED.to_s
          data.merge! ({
                        closed_by_name: wo.closed_by.try(:name),
                        closed_on: wo.closed_at ? l(wo.closed_at, format: :short) : nil,
                        closing_comment: wo.closing_comment,
                        duration: minutes_to_hours(wo.duration),
                        closed_same_day: wo.days_elapsed == 1,
                        days_elapsed: wo.days_elapsed
                      })
        else
          data.merge! ({
                        due_to_date: wo.due_to_date ? l(wo.due_to_date, format: :short) : nil
                      })
        end
        data
      end
      respond_to do |format|
        format.json do
          render json: @results
        end
        format.pdf do
          title = format('Work Order Listing Report')
          @results = @results.select do |wo|
            (params[:status].blank? || params[:status].include?(wo[:status])) &&
              (params[:priority].blank? || params[:priority].include?(wo[:priority_value])) &&
              (params[:location].blank? || params[:location] == wo[:type]) &&
              (params[:checklist].blank? || !(Regexp.new(params[:checklist].join('|')) =~ wo[:location_name]).nil? )
          end
          render pdf: title,
                 template: 'reports/pdf/maintenance_work_orders',
                 layout: 'layouts/pdf.html.haml',
                 header: {
                   html: {
                     template: 'reports/pdf/header',
                     locals: {
                       report_title: title
                     }
                   },
                   spacing: -10
                 },
                 footer: {
                   center: '[page] of [topage]'
                 }
        end
      end
    end
  end

  def maintenance_pm_productivity_data
    maintenance_records = Maintenance::MaintenanceRecord.finished
    maintenance_records = maintenance_records.where(started_at: @from..@to) if params[:date_range].present?

    if params[:location].present?
      maintainable_type = params[:location] == "Other" ? nil : params[:location]
      maintenance_records = maintenance_records.where(maintainable_type: maintainable_type)
    end
    records_duration_data = maintenance_records.map(&:minutes_to_complete)

    duration_ranges = [[0, 15], [15,30], [30,45], [45,60], [60,75], [75, nil]]
    data = duration_ranges.map do |range|
      if range.last.nil?
        label = "<strong>#{range.first}-more</strong><br/>\n minutes"
        value = records_duration_data.count{ |duration| duration > range.first  } 
      else 
        label = "<strong>#{range.first}-#{range.last}</strong><br/>\n minutes" 
        value = records_duration_data.count{ |duration| duration > range.first and duration <= range.last  } 
      end
      [label, value]
    end
    results = [{ "label" => "Completed Room PM Count","color" => "#00B1E1","data" => data }]
    render json: results
  end
  
  def room_pm_progress_data
    if params[:date_range] == "month"
      date_range = (Date.today.end_of_month - ((@dates_offset + 1) * 6).months + 1.day .. Date.today.end_of_month - (@dates_offset * 6).months)
      maintenance_records = Maintenance::MaintenanceRecord.for_rooms.finished.group_by_month(:started_at, range: date_range).count
      label_format = "<strong>%b</strong><br/>\n %Y"
      data = maintenance_records.map{ |record| [ record[0].strftime(label_format), record[1] ] }
    elsif params[:date_range] == "week"
      date_range = (Date.today.end_of_week - ((@dates_offset + 1) * 4).weeks + 1.day .. Date.today.end_of_week - (@dates_offset * 4).weeks)
      maintenance_records = Maintenance::MaintenanceRecord.for_rooms.finished.group_by_week(:started_at, range: date_range).count
      label_format = lambda{ |date| "<strong>#{ date.strftime("%b %d") } - #{ date.end_of_week.strftime("%b %d") }</strong><br/>\n #{ date.strftime("%Y") }" }
      
      data = maintenance_records.map{ |record| [ label_format.call(record[0]), record[1] ] }
    elsif params[:date_range] == "quarter"
      data = []
      period_start = Date.today.beginning_of_year - params[:offset].to_i.years
      4.times do |i|
        maintenance_records_count = Maintenance::MaintenanceRecord.where(created_at: period_start..period_start + 3.month).for_rooms.finished.count
        label = "<strong>#{i + 1}</strong><br/>\n #{period_start.year}" 
        data << [label,maintenance_records_count]
        period_start += 3.month
      end
    end
    
    results = [{ "label" => "Room Pm Progress","color" => "#00B1E1","data" => data }]
    render json: results
  end
  
  def work_order_productivity_data
    if params[:date_range] == "month"
      date_range = (Date.today.end_of_month - ((@dates_offset + 1) * 6).months + 1.day .. Date.today.end_of_month - (@dates_offset * 6).months)

      opened_work_orders = Maintenance::WorkOrder.group_by_month(:created_at, range: date_range).count
      closed_work_orders = Maintenance::WorkOrder.closed.group_by_month(:updated_at, range: date_range).count
      label_format = "<strong>%b</strong><br/>\n %Y"

      opened_data  = opened_work_orders.map{   |record| [ record[0].strftime(label_format), record[1] ] }
      close_data = closed_work_orders.map{ |record| [ record[0].strftime(label_format), record[1] ] }
    elsif params[:date_range] == "week"
      date_range = (Date.today.end_of_week - ((@dates_offset + 1) * 4).weeks + 1.day .. Date.today.end_of_week - (@dates_offset * 4).weeks)
      opened_work_orders = Maintenance::WorkOrder.group_by_week(:created_at, range: date_range).count
      closed_work_orders = Maintenance::WorkOrder.closed.group_by_week(:updated_at, range: date_range).count
      label_format = lambda{ |date| "<strong>#{ date.strftime("%b %d") } - #{ date.end_of_week.strftime("%b %d") }</strong><br/>\n #{ date.strftime("%Y") }" }

      opened_data  = opened_work_orders.map{   |record| [ label_format.call(record[0]), record[1] ] }
      close_data = closed_work_orders.map{ |record| [ label_format.call(record[0]), record[1] ] }
    elsif params[:date_range] == "quarter"
      opened_data,close_data = [],[]
      period_start = Date.today.beginning_of_year - params[:offset].to_i.years
      4.times do |i|
        date_range = period_start..period_start + 3.month
        opened_work_orders = Maintenance::WorkOrder.where(created_at: date_range)
        closed_work_orders = Maintenance::WorkOrder.closed.where(updated_at: date_range)
        label = "<strong>#{i + 1}</strong><br/>\n #{period_start.year}" 
        opened_data << [label, opened_work_orders.count ]
        close_data << [label, closed_work_orders.count ]
        period_start += 3.month
      end
    end
    #results = [{ "label" => "Work Order Productivity","color" => "#00B1E1","data" => data }]
    results = [
      {color: "#f0ad4e", data: opened_data, bars: {order: 2, align: "left"}, label: "Work Orders Opened"},
      {color: "#4cae4c", data: close_data, bars: {order: 1, align: "left"}, label: "Work Orders Fixed"}
    ]
    render json: results
  end

  def guest_room_pm_analysis
    if request.format.html? # Query all data only if report_type exists. In case of html request, report_type is nil
    else
      if current_cycle.nil?
        respond_to do |format|
          format.json { render json: 'Current cycle does not exist' , status: :unprocessable_entity }
        end
      else
        set_property_info(:room)
        @rooms = Maintenance::Room.all

        @results = []

        if params[:report_type] == 'cyclely'
          unless params[:property_switched].present? # if property_switched, ignore cycle param and return current cycle data
            @cycle = Maintenance::Cycle.by_cycle_type(:room).offset(params[:cycle]).first
          end
          @cycle ||= current_cycle
          @results = get_room_pm_data_by_cycle(@cycle, @rooms)
          @remaining_rooms = @results.select { |r| r[:status] == :_remaining }.count

          respond_to do |format|
            format.json { render json: { result: @results, cycle: {number: @cycle.ordinality_number, period: @cycle.period} } }
            format.csv  { }
            format.pdf do
              title = format("Guest Room PM Analysis - Cycle #{@cycle.ordinality_number} (#{@cycle.period})")
              render pdf: title,
                     template: 'reports/pdf/guest_room_pm_analysis_cycle',
                     layout: 'layouts/pdf.html.haml',
                     header: {
                       html: {
                         template: 'reports/pdf/header',
                         locals: {
                           report_title: title
                         }
                       },
                       spacing: -10
                     },
                     footer: {
                       center: '[page] of [topage]'
                     }
            end
          end
        elsif params[:report_type] == 'yearly'
          cycles = Maintenance::Cycle.by_year(params[:year]).by_cycle_type(:room)
          missing_rooms = 0
          total_rooms = 0

          cycles.each_with_index do |cycle|
            @results.push({
                            ordinality_number: cycle.ordinality_number,
                            data: get_room_pm_data_by_cycle(cycle, @rooms)
                          })
          end

          previous_cycle_data = @results.last(2).first
          missing_rooms = previous_cycle_data[:data].select { |r| r[:status] == :_remaining }.count
          total_rooms = previous_cycle_data[:data].count
          @previous_quarter_completion = (1 - missing_rooms / total_rooms.to_f) * 100
          current_cycle_data = @results.last
          missing_rooms = current_cycle_data[:data].select { |r| r[:status] == :_remaining }.count
          total_rooms = current_cycle_data[:data].count

          @current_quarter_completion = (1 - missing_rooms / total_rooms.to_f) * 100

          respond_to do |format|
            format.json { render json: {result: @results, cycle: {year: current_cycle(:room).year, number: current_cycle(:room).ordinality_number}} }
            format.csv  { }
            format.pdf do
              title = format("Guest Room PM Analysis Yearly Report")
              render pdf: title,
                     template: 'reports/pdf/guest_room_pm_analysis_year',
                     layout: 'layouts/pdf.html.haml',
                     header: {
                       html: {
                         template: 'reports/pdf/header',
                         locals: {
                           report_title: title
                         }
                       },
                       spacing: -10
                     },
                     footer: {
                       center: '[page] of [topage]'
                     }
            end
          end
        end
      end
    end
  end

  def public_area_pm_analysis
    if request.format.html? # Query all data only if report_type exists. In case of html request, report_type is nil
    else
      if current_cycle(:public_area).nil?
        respond_to do |format|
          format.json { render json: 'Current cycle does not exist' , status: :unprocessable_entity }
        end
      else
        set_property_info(:public_area)

        @areas = Maintenance::PublicArea.all

        @results = []

        if params[:report_type] == 'cyclely'
          unless params[:property_switched].present? # if property_switched, ignore cycle param and return current cycle data
            @cycle = Maintenance::Cycle.by_cycle_type(:public_area).offset(params[:cycle]).first
          end
          @cycle ||= current_cycle(:public_area)
          @results = get_public_area_pm_data_by_cycle(@cycle, @areas)
          @remaining_areas = @results.select { |r| r[:status] == :_remaining }.count

          respond_to do |format|
            format.json { render json: { result: @results, cycle: {number: @cycle.ordinality_number, period: @cycle.period} } }
            format.csv  { }
            format.pdf do
              title = "Public Area PM Analysis - Cycle C#{@cycle.ordinality_number} (#{@cycle.period})"
              render pdf: title,
                     template: 'reports/pdf/public_area_pm_analysis_cycle',
                     layout: 'layouts/pdf.html.haml',
                     header: {
                       html: {
                         template: 'reports/pdf/header',
                         locals: {
                           report_title: title
                         }
                       },
                       spacing: -10
                     },
                     footer: {
                       center: 'Page [page] of [topage]'
                     }
            end
          end
        elsif params[:report_type] == 'yearly'
          cycles = Maintenance::Cycle.by_year(params[:year]).by_cycle_type(:public_area).last(6)
          missing_areas = 0
          total_areas = 0

          cycles.each_with_index do |cycle|
            @results.push({
                            ordinality_number: cycle.ordinality_number,
                            data: get_public_area_pm_data_by_cycle(cycle, @areas)
                          })
          end

          previous_cycle_data = @results.last(2).first
          missing_areas = previous_cycle_data[:data].select { |r| puts r; r[:status] == :_remaining }.count
          total_areas = previous_cycle_data[:data].count
          @previous_cycle_completion = (1 - missing_areas / total_areas.to_f) * 100

          current_cycle_data = @results.last
          missing_areas = current_cycle_data[:data].select { |r| r[:status] == :_remaining }.count
          total_areas = current_cycle_data[:data].count
          @current_cycle_completion = (1 - missing_areas / total_areas.to_f) * 100

          respond_to do |format|
            format.json { render json: {result: @results, cycle: {year: current_cycle(:public_area).year, number: current_cycle(:public_area).ordinality_number}} }
            format.csv  { }
            format.pdf do
              title = format("Public Area PM Room Analysis Yearly Report")
              render pdf: title,
                     template: 'reports/pdf/public_area_pm_analysis_year',
                     layout: 'layouts/pdf.html.haml',
                     header: {
                       html: {
                         template: 'reports/pdf/header',
                         locals: {
                           report_title: title
                         }
                       },
                       spacing: -10
                     },
                     footer: {
                       center: '[page] of [topage]'
                     }
            end
          end
        end
      end
    end
  end

  def equipment_pm_analysis
    unless request.format.html?
      @filter_range = params[:filter_range] || 'Quarter'
      @equipments = Maintenance::Equipment.active.joins(:equipment_type).merge(Maintenance::EquipmentType.active).reorder('maintenance_equipment_types.row_order ASC, maintenance_equipment.row_order ASC').map do |equipment|
        records = equipment.maintenance_records.finished.where(completed_on: @from..@to).map do |record|
          {
            checklist_group_id: record.equipment_checklist_group_id,
            checklist_group_name: record.equipment_checklist_group.name,
            checklist_group_frequency: record.equipment_checklist_group.frequency_text,
            fixes: record.checklist_item_maintenances.fixed.count,
            issues: record.checklist_item_maintenances.issues.count,
            inspected: record.status == Maintenance::MaintenanceRecord::STATUS_COMPLETED,
            completed_on: record.completed_on
          }
        end
        records = records.group_by { |r|
          @filter_range == 'Quarter' ?
            r[:completed_on].beginning_of_month.strftime('%B') :
            "Week #{r[:completed_on].to_date.day / 7 + 1}"
        }
        {
          id: equipment.id,
          name: equipment.name,
          type_id: equipment.equipment_type.id,
          type_name: equipment.equipment_type.name,
          location: equipment.location,
          maintenance_records: records
        }
      end

      data = nil
      if params[:property_switched] == 'true'
        data = {
          data: @equipments.to_json,
          groups: Maintenance::EquipmentChecklistItem.checklist_groups.select([:equipment_type_id, :id, :name]).map(&:serializable_hash).to_json,
          types: Maintenance::EquipmentType.active.includes(:equipments).merge(Maintenance::Equipment.active).to_json
        }
      end
      data ||= @equipments.to_json

      respond_to do |format|
        format.json { render json: data }
        format.pdf do
          title = format("Equipment PM Analysis Report")
          date = @from
          @steps = []
          while date < @to do
            step = @filter_range == 'Quarter' ? date.strftime('%B') : "Week #{date.strftime('%U').to_i - @from.strftime('%U').to_i + 1}"
            @steps.push step
            @filter_range == 'Quarter' ? date += 1.months : date += 1.weeks
          end
          @selected_groups = (params[:groups] || []).map(&:to_i)
          @selected_types = (params[:types] || []).map(&:to_i)
          @sgroups = Maintenance::EquipmentChecklistItem.where(id: @selected_groups).group_by(&:equipment_type_id)
          @stypes = Maintenance::EquipmentType.where(id: @selected_types)
          render pdf: title,
                 template: 'reports/pdf/equipment_pm_analysis',
                 layout: 'layouts/pdf.html.haml',
                 header: {
                   html: {
                     template: 'reports/pdf/header',
                     locals: {
                       report_title: title
                     }
                   },
                   spacing: -10
                 },
                 footer: {
                   center: '[page] of [topage]'
                 }
        end
      end
    end
  end

  def trending_cloud
    @from = params[:from] || (Date.today - 3.months).to_s
    @from = Date.parse(@from).beginning_of_day
    @to   = params[:to] || Date.today.to_s
    @to   = Date.parse(@to).end_of_day

    wo_data = []
    cim_data = []
    ActiveRecord::lax_includes do
      work_orders = Maintenance::WorkOrder.where(created_at: @from..@to)
                      .includes(maintainable: :equipment_type)
                      .includes(checklist_item_maintenance: :maintenance_checklist_item)
      wo_data = JSON.parse(work_orders.to_json(
                          only: [:id, :maintainable_type],
                          methods: [:maintainable_name, :checklist_item_name]
                        ))

      checklist_item_fixes =
        Maintenance::ChecklistItemMaintenance.fixed.where(created_at: @from..@to)
          .includes(maintenance_record: {maintainable: :equipment_type})
          .includes(:maintenance_checklist_item)
      cim_data = JSON.parse(checklist_item_fixes.to_json(
                           only: [:id],
                           methods: [:maintainable_type, :maintainable_name, :checklist_item_name]
                         ))
    end
    trends = {}
    wo_data.each do |e|
      if e['maintainable_name'].present?
        trends[e['maintainable_name']] ||= {}
        trends[e['maintainable_name']]['weight'] ||= 0
        trends[e['maintainable_name']]['weight'] = trends[e['maintainable_name']]['weight'] + 1
        trends[e['maintainable_name']]['ids'] ||= {}
        trends[e['maintainable_name']]['ids']['wos'] ||= []
        trends[e['maintainable_name']]['location_trend'] = true
        trends[e['maintainable_name']]['ids']['wos'] << e['id'] if e['id'].present?
      end

      if e['maintainable_type'] != 'Other' && e['checklist_item_name'].present?
        trends[e['checklist_item_name']] ||= {}
        trends[e['checklist_item_name']]['weight'] ||= 0
        trends[e['checklist_item_name']]['weight'] = trends[e['checklist_item_name']]['weight'] + 1
        trends[e['checklist_item_name']]['ids'] ||= {}
        trends[e['checklist_item_name']]['location_trend'] = false
        trends[e['checklist_item_name']]['ids']['wos'] ||= []
        trends[e['checklist_item_name']]['ids']['wos'] << e['id'] if e['id'].present?
      end
    end
    cim_data.each do |e|
      if e['maintainable_name'].present?
        trends[e['maintainable_name']] ||= {}
        trends[e['maintainable_name']]['weight'] ||= 0
        trends[e['maintainable_name']]['weight'] = trends[e['maintainable_name']]['weight'] + 1
        trends[e['maintainable_name']]['ids'] ||= {}
        trends[e['maintainable_name']]['ids']['cim'] ||= []
        trends[e['maintainable_name']]['ids']['cim'] << e['id'] if e['id'].present?
      end

      if e['maintainable_type'] != 'Other' && e['checklist_item_name'].present?
        trends[e['checklist_item_name']] ||= {}
        trends[e['checklist_item_name']]['weight'] ||= 0
        trends[e['checklist_item_name']]['weight'] = trends[e['checklist_item_name']]['weight'] + 1
        trends[e['checklist_item_name']]['ids'] ||= {}
        trends[e['checklist_item_name']]['ids']['cim'] ||= []
        trends[e['checklist_item_name']]['ids']['cim'] << e['id'] if e['id'].present?
      end
    end
    data = trends.collect { |k, v| {text: k}.merge!(v) }.sort_by { |a| -a['weight'] }[0..19]

    render json: data.to_json
  end

  def work_order_trendings
    unless request.format.html?
      if params[:wo_ids]
        work_orders = Maintenance::WorkOrder.includes(:opened_by).order_by_priority
        work_orders = work_orders.where(id: params[:wo_ids])
        work_orders = work_orders.map do |wo|
          data = {
            id: wo.id,
            description: wo.description,
            priority: t("reports.work_order_trendings.priority.#{wo.priority}"),
            opened_by_name: wo.opened_by.name,
            location_name: wo.location_name,
            status: work_order_status_labels[wo.status.to_sym],
            type: wo.maintainable_type,
            priority_value: wo.priority,
            days_opened: wo.days_opened,
            is_unassigned: wo.assigned_to_id == Maintenance::WorkOrder::UNASSIGNED,
            assigned_to_name: work_order_assigned_to(wo),
            materials_exists: wo.materials.count > 0,
            material_items: wo.materials.map do |m|
              {
                quantity: quantity_format(m.quantity),
                unit: m.item.inventory_unit.name,
                name: m.item.name
              }
            end,
            materials_cost: humanized_currency_format(wo.material_total),
            detail_exists: wo.materials.count > 0 || wo.closing_comment.present? || wo.duration.present?
          }
          if wo.status == Maintenance::WorkOrder::STATUS_CLOSED.to_s
            data.merge! ({
                          closed_by_name: wo.closed_by.try(:name),
                          closed_on: wo.closed_at ? l(wo.closed_at, format: :short) : nil,
                          closing_comment: wo.closing_comment,
                          duration: minutes_to_hours(wo.duration),
                          closed_same_day: wo.days_elapsed == 1,
                          days_elapsed: wo.days_elapsed
                        })
          else
            data.merge! ({
                          due_to_date: wo.due_to_date ? l(wo.due_to_date, format: :short) : nil
                        })
          end
          data
        end
      end
      if params[:cim_ids]
        fixes = Maintenance::ChecklistItemMaintenance.where(id: params[:cim_ids])
        fixes = fixes.map do |cim|
          checklist_item = cim.maintenance_checklist_item
          data = {
              comment: cim.comment,
              location: params[:checklist_trends] == 'true' ? cim.checklist_item_name : cim.maintainable_name,
              started_on: cim.maintenance_record ? l(cim.maintenance_record.created_at, format: :short) : nil,
              started_by: cim.maintenance_record ? cim.maintenance_record.user.try(:name) : nil
          }
          if cim.maintenance_record && cim.maintenance_record.completed_on
            data.merge!({
              completed_on: l(cim.maintenance_record.completed_on, format: :short),
              completed_by: cim.maintenance_record.completed_by.try(:name)
            })
          end
          data
        end
      end

      @results = {
          work_orders: work_orders,
          fixes: fixes
      }
      respond_to do |format|
        format.json { render json: @results }
        format.pdf do
          title = format("Hotel Trending Issue Analysis")
          render pdf: title,
                 template: 'reports/pdf/work_order_trendings',
                 layout: 'layouts/pdf.html.haml',
                 header: {
                     html: {
                         template: 'reports/pdf/header',
                         locals: {
                             report_title: title
                         }
                     },
                     spacing: -10
                 },
                 footer: {
                     center: '[page] of [topage]'
                 }
        end
      end
    end
  end

  private

  def get_date_range
    @from = params[:from] || Date.today.to_s
    @from = Date.parse(@from).beginning_of_day
    @to   = params[:to] || Date.today.to_s
    @to   = Date.parse(@to).end_of_day
    @dates_offset = params[:offset].to_i
  end

  def get_room_pm_data_by_cycle(cycle, rooms)
    rooms.map do |room|
      records = room.maintenance_records.by_cycle(cycle)
      checklist_items_maintenances = Maintenance::ChecklistItemMaintenance.where(maintenance_record_id: records.pluck(:id))
      {
        id: room.id,
        room_no: room.name,
        floor: room.floor,
        no_issues: checklist_items_maintenances.no_issues.count,
        fixed: checklist_items_maintenances.fixed.count,
        issues: checklist_items_maintenances.issues.count,
        count_of_pm: records.count,
        status: if records.completed.present?
                  :completed
                elsif records.finished.present?
                  :finished
                else
                  :_remaining
                end
      }
    end
  end

  def get_public_area_pm_data_by_cycle(cycle, areas)
    areas.map do |area|
      records = area.maintenance_records.by_cycle(cycle).finished
      checklist_items_maintenances = Maintenance::ChecklistItemMaintenance
                                       .where(maintenance_record_id: records.pluck(:id))
      {
        id: area.id,
        name: area.name,
        no_issues: checklist_items_maintenances.no_issues.count,
        fixed: checklist_items_maintenances.fixed.as_json(include: [:maintenance_checklist_item, :maintenance_equipment_checklist_item]),
        issues: checklist_items_maintenances.issues.as_json(include: [:work_order]),
        count_of_pm: records.count,
        maintenance_records: maintenance_records_serializer(records),
        status: if records.completed.present?
                  :completed
                elsif records.finished.present?
                  :finished
                else
                  :_remaining
                end
      }
    end
  end

  # TODO: Need to use active_model_serializer
  def maintenance_records_serializer(records)
    results = records.map do |record|
      hash = {
        completed_by: record.completed_by.try(:name),
        completed_on: I18n.l(record.completed_on, format: :short),
        inspected: record.completed?
      }

      if record.completed?
        hash.merge! inspected_by: record.inspected_by.try(:name)
        hash.merge! inspected_on: I18n.l(record.inspected_on, format: :short)
      end
      hash
    end
  end

  def set_property_info(cycle_type)
    return unless params[:property_switched].present?

    response.headers['cycle_count'] = Maintenance::Cycle.by_cycle_type(cycle_type).count.to_s
    response.headers['cycle_offset'] = (Maintenance::Cycle.by_cycle_type(cycle_type).count - 1).to_s
    response.headers['min_year'] = Maintenance::Cycle.by_cycle_type(cycle_type).minimum(:year).to_s
    response.headers['max_year'] = Maintenance::Cycle.by_cycle_type(cycle_type).maximum(:year).to_s
    response.headers['current_cycle'] = "C#{current_cycle(cycle_type).ordinality_number} (#{current_cycle(cycle_type).period})"
  end
end
