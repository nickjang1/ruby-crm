module ActivityHelper
  def maintenance_record_status(record)
    if record.checklist_item_maintenances.fixed.empty? && record.checklist_item_maintenances.issues.empty?
      t("activity.maintenance_record.#{record.status}.no_issues", type: record.maintainable_type_short.titleize)
    else
      issue_count = record.checklist_item_maintenances.issues.count
      fix_count = record.checklist_item_maintenances.fixed.count
      data = []
      data.push("#{pluralize(issue_count, 'WO')} created") if issue_count > 0
      data.push("#{pluralize(fix_count, 'issue')} fixed") if fix_count > 0
      data.join(' and ')
    end
  end

  def activity_type_options
    [
      ['All activities', nil],
      ['Work Order', 'work_order'],
      ['Room PM', 'room.pm'],
      ['Public Area PM', 'public_area.pm'],
      ['Equipment PM', 'equipment.pm'],
      ['Guest Log', 'comment']
    ]
  end
end