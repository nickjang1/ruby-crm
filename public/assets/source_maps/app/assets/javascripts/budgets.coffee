getMonthName = (month) ->
  moment().month(month).format('MMMM')
  
getMonthAbbrName = (month) ->
  moment().month(month).format('MMM')

budgetsPage = ->
  unless $('body').hasClass('budgets-page')
    return

  $budget_panel = $("#budgets-panel");
  $scope_form = $budget_panel.find('form#budget-scope-form')
  $modal = $('#add-budget-modal')
  $delete_btn = $('#add-budget-modal').find('#btn-delete-budget')
  $delete_btn.hide()
  budget_template = $('.budget-item-template').html()
  $selectize = $('select.selectize-categories').selectize()[0].selectize
  
  cell = (category_id, month) ->
    $budget_panel.find("#budgets-table tr[data-category-id=\"#{category_id}\"] td[data-month=\"#{month}\"]")
  
  updateTotal = ->
    $budget_panel.find('#budgets-table td.month-total').attr('data-total', '0.0')
    $budget_panel.find('#budgets-table td.month-total').html('')
    for tr in $budget_panel.find('#budgets-table tr').slice(2)
      for td in $(tr).find('td:not(:first)')
        month = $(td).attr('data-month')
        $total_td = $budget_panel.find("#budgets-table td.month-total[data-month=\"#{month}\"]")
        if $(td).attr('data-amount')
          total = formatPrice(parseFloat($total_td.attr('data-total')) + parseFloat($(td).attr('data-amount')))
          $total_td.attr('data-total', total)
          $total_td.html("$#{total}") if total > 0
  
  renderBudget = (budget) ->
    if budget.year != $budget_panel.find('#budgets-table').data('year')
      return
    budget.amount = formatPrice(budget.amount)
    rendered = Mustache.render(
      budget_template
      budget: budget
    )
    $cell = cell(budget.category_id, budget.month)
    $cell.html(rendered)
    $cell.attr('data-amount', budget.amount)
  
  renderBudgets = (budgets) ->
    for budget in budgets
      renderBudget(budget)
    updateTotal()

  $scope_form.bind 'ajax:success', (event, data) ->
    year = data.year
    month = data.first_half * 6
    $budget_panel.find('.toolbar-title').text("#{getMonthAbbrName(month)} ~ #{getMonthAbbrName(month+5)}, #{year}")
    for td, i in $budget_panel.find('#budgets-table thead td:not(:first)')
      $(td).text(getMonthName(month + i))
    budgets = JSON.parse(data.budgets)
    $budget_panel.find('#budgets-table .budget-item').remove()
    renderBudgets(budgets)
    $('#loading').hide()

  $('.btn-budgets-scope').on 'click', (e) ->
    e.preventDefault()
    $('#loading').show()
    year = parseInt($scope_form.find('input[name="year"]').val())
    first_half = parseInt($scope_form.find('input[name="first_half"]').val())
    $budget_panel.find('#budgets-table td').removeClass('highlight')
    $budget_panel.find('#budgets-table td').attr('data-amount', '0.0')
    if $(@).data('scope') == 'next'
      year += first_half
      first_half = 1 - first_half
    else if $(@).data('scope') == 'prev'
      first_half = 1 - first_half
      year -= first_half
    
    for tr in $budget_panel.find('#budgets-table tr')
      for td, i in $(tr).find('td:not(:first)')
        $(td).attr('data-month', first_half * 6 + i + 1)
    $budget_panel.find('#budgets-table').data('year', year)

    current_month = moment().format('M')
    if year == parseInt(moment().format('YYYY'))
      $budget_panel.find("#budgets-table td[data-month=\"#{current_month}\"]:not(:first)").addClass('highlight')
    $scope_form.find('input[name="year"]').val(year)
    $scope_form.find('input[name="first_half"]').val(first_half)
    $scope_form.submit()
    
  $('#budget-form button[type="submit"]').on 'click', (e)->
    e.preventDefault()
    $amount = $('#budget-form').find('input#budget_amount')
    if $amount.val() is ''
      $amount.parent().parent().find('ul.parsley-errors-list').remove()
      $amount.parent().after("<ul class='parsley-errors-list filled'><li class='parsley-required'>Amount is required.</li></ul>")
      return false
    else
      $amount.removeClass('parsley-error')
      $amount.parent().parent().find('ul.parsley-errors-list').remove()
      $(@).attr('disabled', 'disabled')
      $('#budget-form').submit()
      
  $('#add-budget-modal').on 'shown.bs.modal', ->
    $('#budget-form button[type="submit"]').removeAttr('disabled')
  
  $('#budget-form').bind 'ajax:success', (event, data) ->
    $('#add-budget-modal').modal('hide')
    if (data.old_category_id && data.old_month)
      cell(data.old_category_id, data.old_month).attr('data-amount', "0.0")
      cell(data.old_category_id, data.old_month).html('')
    if (data.budgets)
      renderBudgets(data.budgets)
    else
      updateTotal()
    
  $('#btn-add-budget').on 'click', (e) ->
    $modal.find('.modal-title').text('Add Budget Item')
    $modal.find('#budget_amount').val('')
    $selectize.clear()
    $modal.find('#budget-form').attr('method', 'post')
    $modal.find('#budget-form').attr('action', Routes.budgets_path())
    $selectize.enable()
    $delete_btn.hide()
    $modal.modal('show')
    
  $(document).on 'click', '.budget-item', (e) ->
    budget_id = $(@).attr('data-budget-id')
    e.preventDefault()
    $.ajax
      url: Routes.edit_budget_path(budget_id)
      type: 'GET'
      dataType: 'json'
      success: (data) ->
        $modal.find('#budget_amount').val(data.amount)
        $modal.find('#budget_year').val(data.year)
        $modal.find('#budget_month').val(data.month)
        $selectize.clear()
        $selectize.addItem(data.category_id)
        $selectize.disable()
        $modal.find('.modal-title').text('Edit Budget Item')
        $modal.find('#budget-form').attr('method', 'put')
        $modal.find('#budget-form').attr('action', Routes.budget_path(budget_id))
        $modal.modal('show')
        $delete_btn.show()
        $delete_btn.attr('href', Routes.budget_path(budget_id))
  
  $delete_btn.bind 'ajax:success', (event, data) ->
    td = cell(data.category_id, data.month)
    td.attr('data-amount', "0.0")
    td.html('')

$(document).ready(budgetsPage)
