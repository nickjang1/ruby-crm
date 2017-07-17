itemsListingPage = ->
  return unless $('body').hasClass('items-listing-page')
  selected_ids = []

  validate_delete = (value) ->
    $("#delete_selected").attr('disabled', value)

  validate_order = (value) ->
    $("#order_selected_items").attr('disabled', value)

  $("#delete_selected").on 'click', ->
    if selected_ids.length
      window.location.href = Routes.destroy_items_path ids: selected_ids
    else
      alert "You must select Items"

  $("#order_selected_items").on 'click', (e)->
    e.preventDefault()
    if selected_ids.length
      window.location.href = Routes.new_purchase_request_path q: {id_in: selected_ids}
    else
      alert "You must select Items"

  $("input#customcheckbox-item-select-all").on 'change', (e) ->
    value = $(e.target).prop('checked')
    checkboxes = $('.table-wrapper table tbody input[type="checkbox"]')
    checkboxes.prop('checked', value)
    checkboxes.change()#('change')

  $(document).on 'change', '.table-wrapper table tbody input[type="checkbox"]', ->
    if $(@).prop('checked')
      selected_ids.push $(@).val() if selected_ids.indexOf( $(@).val() ) < 0
    else
      index = selected_ids.indexOf( $(@).val() )
      selected_ids.splice(index, 1)

    if selected_ids.length
      validate_delete(false)
      validate_order(false)
    else
      validate_delete(true)
      validate_order(true)

    all_records = $('.table-wrapper table tbody input[type="checkbox"]')
    if selected_ids.length == all_records.length
      $("#customcheckbox-item-select-all").prop('checked', true)
    else
      $("#customcheckbox-item-select-all").prop('checked', false)

  $('.table-wrapper table tbody input[type="checkbox"]:checked').trigger('change')

  options =
    bPaginate: false
    bInfo: false
    bFilter: false

    aoColumnDefs: [
      bSortable: false
      aTargets: ["nosort"]
    ]
  (new Image()).src = '/assets/adminre_theme_v120/image/loading/spinner.gif' # preloading spinner img
  ajaxIsLoadingIndicator = $('#loading-next-page-indicator')#.removeClass('show') # spinner
  loadedItemsCounter     = $('#loaded-items-counter') # indicator for loaded items counts
  totalItemsCounter      = $('#total-items-counter')  # indicator for total items counts
  itemsTable             = $('.table-wrapper table')
  scrollToLoadMore       = $('#scroll-down-to-load-more')
  itemsDataTable         = $('.table-wrapper table').DataTable(options)
  itemCheckboxTemplate   = $('.items-checkbox').html()

  currentPage = 2
  perPage     = 10
  $window     = $(window)
  loading     = false
  endOfCollection = false
  ajaxData = { search: {} }

  loadItemsFromServer = ->
    unless endOfCollection
      ajaxIsLoadingIndicator.addClass('show')
      scrollToLoadMore.hide()
      loading = true
      
      $.ajax
        url: Routes.items_path(format: 'json', page: currentPage)
        type: 'GET'
        data: ajaxData
        success: (data)->
          numItemsLoaded = (data.items && data.items.length) || 0
          currentPage += 1
          loading = false
          if numItemsLoaded < perPage
            endOfCollection = true
          else
            scrollToLoadMore.show()

          $(data.items).each (i, el)->
            renderedCheckbox = Mustache.render(
              itemCheckboxTemplate, 
                item: 
                  id: el.id
            )
            itemsDataTable.row.add( [
              renderedCheckbox
              el.number
              el.name
              """<span class="text-muted semibold">#{ el.unit }</span>"""
              el.par_level
              if !!el.vendors then el.vendors else ""
            ] ).draw()
          previousLoadedItems = parseInt(loadedItemsCounter.text())
          loadedItemsCounter.text(previousLoadedItems + numItemsLoaded)
          totalItemsCounter.text(data.collection_size)
        # error: ->
        #   currentPage -= 1
        complete: -> ajaxIsLoadingIndicator.removeClass('show')

  $(document).bind "scroll", ->
    windowBottom = $window.scrollTop() + $window.height()
    # SCROLLED TO THE END OF SCREEN: LOADING NEXT PAGE
    if !loading && (windowBottom + 30) >= $(document).height()
      loadItemsFromServer()
  
  # Need to trigger scroll event if page doesn't have scroll
  $(document).trigger('scroll')

  itemsTable.find('thead input[data-search-column]').add('#search-filter').on 'change', ->
    _this = $(this)
    ajaxData.search[ _this.data('search-column') ] = _this.val()
    itemsDataTable.clear().draw()
    currentPage = 1
    endOfCollection = false
    loadedItemsCounter.text("0")
    loadItemsFromServer()

$(document).ready(itemsListingPage)
