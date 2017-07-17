itemFormPage = ->
  return unless $('body').hasClass('item-form')

  if $('form').hasClass('locked')
    $(':input').attr('disabled', true)
    $('.selectized')[0].selectize.disable()
    return

  purchasedAs      = $('#purchased-as')
  packUnit         = $('#pack-unit')
  subpackUnit      = $('#subpack-unit')
  purchaseCostUnit = $('#purchase-cost-unit')
  inventoryUnit    = $('#inventory-unit')
  parUnits         = $('#par-units')
  purchaseAndCostUnits = purchaseCostUnit.add(inventoryUnit)

  selectedUnitsArray  = []
  availableUnitsArray = $('#units').data('values')

  initialInventoryUnitVal    = inventoryUnit.find('option:selected').val()
  initialPurchaseCostUnitVal = purchaseCostUnit.find('option:selected').val()

  # Purchased AS
  pack    = $('#pack')
  subpack = $('#subpack')

  updateSelectedUnitsArray = (i, val)->
    selectedUnitsArray[i] = val

    purchaseAndCostUnits.find('option').remove()
    purchaseAndCostUnits.append(
      # purchaseCostUnit and inventoryUnit should to select only previously chosen units
      """<option value="">SELECT UNIT</option>""" + 
      $.map($.grep(availableUnitsArray, (elem, i) -> $.inArray( "#{ elem[0] }", selectedUnitsArray ) >= 0), (elem)->
        """<option value="#{ elem[0] }">#{ elem[1] }</option>"""
      ).join("")
    )

  purchasedAs.on('change', ->
    val  = $(@).val()
    text = $(@).find('option:selected').text()
    updateSelectedUnitsArray(0, val)
    if !!val
      pack.find('label').text("#{ text }=")
      pack.find(':input').removeAttr('disabled').trigger('change')
    else
      pack.add(subpack).find(':input').attr('disabled', true)

  ).trigger('change')

  # Pack Unit  
  packUnit.on('change', ->
    val  = $(@).val()
    text = $(@).find('option:selected').text()
    updateSelectedUnitsArray(1, val)
    if !!val
      subpack.find('label').text("#{ text }=")
      subpack.find(':input').removeAttr('disabled')
    else
      subpack.find(':input').attr('disabled', true)

  ).trigger('change')

  # subpack unit
  subpackUnit.on('change', ->
    updateSelectedUnitsArray(2, $(@).val())
  ).trigger 'change'

  inventoryUnit.val(initialInventoryUnitVal)
  purchaseCostUnit.val(initialPurchaseCostUnitVal)

  # inventory unit
  inventoryUnit.on('change', ->
    parUnits.text $(@).find('option:selected').text()
  ).trigger 'change'

  checkIfLastVendor = ->
    $('#vendors .vendor .remove_btn').toggleClass('hidden', $('#vendors .vendor').length == 1)


  checkIfLastVendor()

  # VENDORS
  $itemId = $('#item-id').data('value')

  $('body').on 'change', '#vendors .vendor input[type="checkbox"]', ->
    changedCheck = @
    $('#vendors .vendor input[type="checkbox"]').each ->
      $(@).prop("checked", false) unless changedCheck is @


  $('body').on 'dialog.confirmed', '#vendors .vendor .remove_btn', ->
    self = $(@)
    currentVendorItem = self.parents('.vendor')
    vendorId = currentVendorItem.data('id')
    if !!vendorId && $itemId
      currentVendorItem.hide()
      $.ajax
        url: Routes.item_path($itemId)
        dataType: 'json'
        method: "PUT"
        data: { item: { vendor_items_attributes: { id: vendorId, _destroy: true } }}
        success: (data)->
          currentVendorItem.remove()
          checkIfLastVendor()
        error: ->
          currentVendorItem.show()
    else
      currentVendorItem.remove()
      checkIfLastVendor()


  $('#add_vendor').click ->
    newVendor = $('#vendors .vendor:last-child').clone()
    newVendor.find('.price_input, .sku_input, .id_hidden_field').val("")
    newVendor.find('input[type="checkbox"]').prop("checked", false)

    uniqId = new Date().getTime()

    newVendor.removeAttr('data-id')
    newVendor.find(':input').each ->
      name = $(@).prop('name')
      number = parseInt( name.match(/\d/g)[0] )
      $(@).prop('name', name.replace(/(\d)/g, number + 1 ))
    newVendor.find('select').prop('selectedIndex', 0)
    newVendor.find('a[data-toggle="collapse"]').prop('href', "##{ uniqId }")
    newVendor.find('.panel-collapse').prop('id', "#{ uniqId }")
    newVendor.find('.checkbox.custom-checkbox input[type="checkbox"]').prop('id', "checkbox-#{ uniqId }")
    newVendor.find('.checkbox.custom-checkbox label').prop('for', "checkbox-#{ uniqId }")
    newVendor.find('input.currency-input').numeric(decimalPlaces: 2)
    newVendor.appendTo('#vendors')
    checkIfLastVendor()


$(document).ready(itemFormPage)
