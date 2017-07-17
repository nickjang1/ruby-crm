module CapybaraMacros
  def visit_with_delete(url)
    page.driver.submit :delete, url, {}
  end
  
  def nth_row_nth_column(table, row_nth, column_nth)
    row_nth_selector = case row_nth
      when "first"  then "tr:first-child"
      when "last"   then "tr:last-child"
      else                "tr:nth-child(#{row_nth})"
    end
    
    column_nth_selector = case column_nth
      when "first"  then "td:first-child"
      when "last"   then "td:last-child"
      else               "td:nth-child(#{column_nth})"
    end
    
    page.find(table).find("tbody #{row_nth_selector} #{column_nth_selector}")
  end
  
end
