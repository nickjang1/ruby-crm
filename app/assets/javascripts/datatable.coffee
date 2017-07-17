#*! ========================================================================
# * datatable.js
# * Page/renders: table-datatable.html
# * Plugins used: datatable
# * ======================================================================== */

jQuery.fn.dataTableExt.oSort["avg_orders_sorter-asc"] = (x, y) ->
  x = 0.5 if !parseInt(x) and x isnt 0
  y = 0.5 if !parseInt(y) and y isnt 0

  return 1 if x > y
  return -1 if x < y
  return 0 if x is y

jQuery.fn.dataTableExt.oSort["avg_orders_sorter-desc"] = (x, y) ->
  x = 0.5 if !parseInt(x) and x isnt 0
  y = 0.5 if !parseInt(y) and y isnt 0

  return -1 if x > y
  return 1 if x < y
  return 0 if x is y

$(document).ready ->
  $table = $("table.column-filtering")
  options = 
    bPaginate: false
    oLanguage:
      sInfo: "showing _TOTAL_ of _MAX_"
      sInfoFiltered: ""
    sDom: "<'row'<'col-sm-6'l><'col-sm-6'f>><''rt><'row'<'col-sm-6'p><'col-sm-6'i>>"

    aoColumnDefs: [
      bSortable: false
      aTargets: ["nosort"]
    ]

  if $table.hasClass('no-initial-sorting')
    options.aaSorting = [] # disable initial sorting
  if $table.hasClass('no-stripe-classes')
    options.stripeClasses = []

  oTable = $table.dataTable(options)
  $table.on "keyup", "input[type=search]", ->
    thisTable = $(this).parents("table.searchable-table")
    thisTable.dataTable().fnFilter @value, thisTable.find("thead input").index(this)
    return

  $table.find(".count-input").on("input change keydown keyup", ->
    $this = $(this)
    badgeCell = $this.parents("tr").find(".skip-inv-cell")
    $this.closest("td").find("input.skip_input").val (if !!$this.val() then "" else true)
    if $this.val() is ""
      badgeCell.find(".blank-to-skip").hide()
      badgeCell.find(".skip").show()
    else
      badgeCell.find(".blank-to-skip").show()
      badgeCell.find(".skip").hide()
    return
  ).change()
  $(".table-info").each (idx) ->
    info = $($(this).parents(".table-wrapper")).find(".dataTables_info")
    $(this).append info
    return