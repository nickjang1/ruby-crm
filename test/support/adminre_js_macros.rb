def fill_in_selectized(key, *values)
  values.flatten.each do |value|
    page.execute_script(%{
      $('.#{key} .selectize-input input').val('#{value}');
      $('.#{key} select.selectized').selectize()[0].selectize.createItem();
    })
  end
end
