module ReportHelper
  def room_status(record)
    return if record.nil?
    status = ''
    detail = ''
    if record[:status] == :completed
      status = "<i class='fa fa-info-circle text-primary'></i>"
    end

    if record[:status] == :_remaining
      status += "<i class='fa fa-times-circle text-danger'></i>"
    else
      status += "<i class='fa fa-check text-success'></i>"
      status += " (#{record[:count_of_pm]} <b class='text-default'>PMs</b>)" if record[:count_of_pm] > 1
    end

    if (record[:fixed] && record[:fixed] > 0)
      detail += "<br>#{record[:fixed]} <b class='text-default'>fixes</b>"
    end
    if (record[:issues] && record[:issues] > 0)
      detail += "<br>#{record[:issues]} <b class='text-default'>WOs</b>"
    end
    "#{status}#{detail}".html_safe
  end

  def area_status(record)
    return if record.nil?
    status = ''
    detail = ''
    if record[:status] == :completed
      status = "<i class='fa fa-info-circle text-primary'></i>"
    end

    if record[:status] == :_remaining
      status += "<i class='fa fa-times-circle text-danger'></i>"
    else
      status += "<i class='fa fa-check text-success'></i>"
      status += " (#{record[:count_of_pm]} <b class='text-default'>PMs</b>)" if record[:count_of_pm] > 1
    end

    if (record[:fixed].count > 0)
      detail += "<br>#{record[:fixed].count} <b class='text-default'>fixes</b>"
    end
    if (record[:issues].count > 0)
      detail += "<br>#{record[:issues].count} <b class='text-default'>WOs</b>"
    end
    "#{status}#{detail}".html_safe
  end

  def pdf_image_tag(image, options = {})
    options[:src] = 'file:///' + File.expand_path(Rails.root) + '/vendor' + image
    options[:src]
  end

  # Convert cycle to quarter
  def c2q(cycle)
    "C#{cycle}"
  end
end
