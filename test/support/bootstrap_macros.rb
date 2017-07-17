module BoostrapMacros
  def inline_error_for(id, assertions)
    within("##{id} + ul.parsley-errors-list") do
      assertions.each do |assertion, value|
        page.text.send assertion, value
      end
    end
  end

  def flash_messages
    page.has_css?('.alert-messages') #to make capybarra wait
    JSON.parse( find(:css, '.alert-messages')["data-messages"] )
  end

  def find_notification type, message
    find("div.alert.alert-#{type} p", text: message)
  end

  def find_link_with_icon class_name, icon, text
    find(:xpath, "//a[contains(@class, \"#{class_name}\") and contains(text(), \"#{text}\")]/i[contains(@class, \"#{icon}\")]")
  end
  
  def find_button_with_icon class_name, icon, text
    find(:xpath, "//button[contains(@class, \"#{class_name}\") and contains(text(), \"#{text}\")]/i[contains(@class, \"#{icon}\")]")
  end

  def all_link_with_icon class_name, icon, text
    all(:xpath, "//a[contains(@class, \"#{class_name}\") and contains(text(), \"#{text}\")]/i[contains(@class, \"#{icon}\")]")
  end
end
