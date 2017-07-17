module ApplicationHelper
  def alert_class(flash_name)
    case flash_name.to_sym
      when :notice then 'success'
      when :alert then 'warning'
      when :error then 'danger'
    end
  end

  def alert_icon(flash_name)
    content_tag :i, nil, class: 'icon-' + case flash_name.to_sym
      when :notice then 'ok'
      when :alert then 'minus-sign'
      when :info then 'info-sign'
      else 'warning-sign'
    end.html_safe
  end

  def breadcrumb(*items)
    content_tag :ul, class: 'breadcrumb' do
      items.collect do |item|
        item = item.to_s.html_safe
        content_tag :li, class: conditional_class({class: 'active', if: item == items.last}) do
          if item == items.last
            item
          else
            item + content_tag(:span, '/', class: 'divider')
          end
        end
      end.join("\n").html_safe
    end
  end

  def age_class(record)
    if record.updated_at > 3.days.ago
      'new'
    elsif record.updated_at > 5.days.ago
      'old'
    else
      'oldest'
    end
  end

  def currency_format value
    ('%.2f' % Money.new((value || 0) * 100)).to_f.to_s
  end

  def humanized_currency_format value
    "$#{currency_format value}"
  end

  def quantity_format value
    ('%.3f' % value).to_f.to_s
  end

  def unit_format unit
    unit.try(:name).upcase
  end

  def humanized_unit_format unit
    content_tag(:span, unit_format(unit), class: 'text-muted semibold')
  end

  # Usage:
  # conditional_class 'btn', {class: 'btn-primary', :if => true}
  # conditional_class 'btn', {class: 'btn-primary', :if => false}, {class: 'btn-warning', :if => true}
  # conditional_class({class: 'btn', :if => true}, {class: 'active', :if => true})

  # This is a tricy method, use :if => condition in the console, if: condition will work fine outside of IRB.
  # Use parenthesis when the unconditional class (first argument, String) is not provided.
  def conditional_class(*args)
    result = []
    result << args.shift if args.first.kind_of? String 
    result |= args.collect {|each| each[:class] if each[:if]}
    result.reject(&:blank?).join ' '
  end

  def options_from_collection_for_select_with_data(collection, value_method, text_method, selected = nil, data = {})
    options = collection.map do |element|
      [element.send(text_method), element.send(value_method), data.map do |k, v|
        {"data-#{k}" => element.send(v)}
      end
      ].flatten
    end
    selected, disabled = extract_selected_and_disabled(selected)
    select_deselect = {}
    select_deselect[:selected] = extract_values_from_collection(collection, value_method, selected)
    select_deselect[:disabled] = extract_values_from_collection(collection, value_method, disabled)
    options_for_select(options, select_deselect)
  end

  # Usage:
  # link_to_with_icon 'icon-info', 'Information', information_path
  #def link_to_with_icon(*args, &block)
    #if block_given?
      #raise ArgumentError.new('A block argument is not supported by this Helper, use link_to instead.')
    #else
      #icon = args.shift
      #name = args.shift
      #link_to *args do
        #content_tag(:i, nil, class: icon) + raw(name.prepend '&nbsp;&nbsp;')
      #end
    #end
  #end
  
  def link_to_with_icon(*args, &block)
    icon = args.shift
    name = args.shift
    link = link_to *args do
      concat content_tag(:i, nil, class: icon)
      concat " "
      concat raw(name)
    end
    link + " " #whitespace for buttons
  end

  
  # Deprecated in Rails 4!
  def link_to_function(name, *args, &block)
     html_options = args.extract_options!.symbolize_keys

     function = block_given? ? update_page(&block) : args[0] || ''
     onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
     href = html_options[:href] || '#'

     content_tag(:a, name, html_options.merge(:href => href, :onclick => onclick))
  end

  def link_to_submit(*args, &block)
    link_to_function (block_given? ? capture(&block) : args[0]), "$(this).closest('form').submit()", args.extract_options!
  end

  def procurement_active?
    lists_active? || purchase_requests_active? || purchase_orders_active? || items_active? || procurement_setup_active?    
  end

  def body_class(class_name)
    content_for :body_class, class_name
  end

  def procurement_setup_active?
    vendors_active? || categories_active? || locations_active?
  end

  def favorie_reports_active?
    reports_active? and params['action'] == 'favorites'
  end

  def preventive_maintenance_active?
    request.fullpath.start_with?('/maintenance/')
  end

  def users_menu_active?
    users_active? || departments_active?
  end

  MENU_ITEMS = %W[departments categories vendors users lists locations items purchase_requests purchase_orders reports budgets]

  MENU_ITEMS.each do |item|
    method_name = "#{item}_active?"
    define_method method_name do
      params[:controller] == item
    end
  end
end
