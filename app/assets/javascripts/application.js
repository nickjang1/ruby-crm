//= require pusher.min
//= require array-find-index-polyfill
//= require adminre_theme_v120/library/jquery/js/jquery.min
//= require adminre_theme_v120/plugins/jqueryui/js/jquery-ui.min
//= require adminre_theme_v120/library/jquery/js/jquery-migrate.min
//= require jquery_ujs
//= require adminre_theme_v120/library/bootstrap/js/bootstrap.min
//= require adminre_theme_v120/library/core/js/core
//= require adminre_theme_v120/plugins/sparkline/js/jquery.sparkline
//= require adminre_theme_v120/javascript/app.js
//= require adminre_theme_v120/plugins/bootbox/js/bootbox
//= require adminre_theme_v120/plugins/flot/jquery.flot
//= require adminre_theme_v120/plugins/flot/jquery.flot.categories
//= require adminre_theme_v120/plugins/flot/jquery.flot.tooltip
//= require adminre_theme_v120/plugins/flot/jquery.flot.resize
//= require adminre_theme_v120/plugins/flot/jquery.flot.spline
//= require adminre_theme_v120/plugins/flot/jquery.flot.pie
//= require jquery.flot.orderBars
//= require adminre_theme_v120/plugins/selectize/js/selectize
//= require selectize-no-delete
//= require selectize-no-results
//= require adminre_theme_v120/plugins/gritter/js/jquery.gritter
//= require adminre_theme_v120/plugins/datatables/js/jquery.datatables
//= require adminre_theme_v120/plugins/datatables/tabletools/js/tabletools
//= require adminre_theme_v120/plugins/datatables/tabletools/js/zeroclipboard
//= require adminre_theme_v120/plugins/datatables/js/jquery.datatables-custom
//= require adminre_theme_v120/plugins/inputmask/js/inputmask.min
//= require adminre_theme_v120/plugins/select2/js/select2.min
//= require daterangepicker/daterangepicker
//= require jquery.marquee
//= require moment-timezone

//= require datatable
//= require jquery.numeric
//= require date
//= require jquery.ba-throttle-debounce
//= require highchart-4.0.4/highcharts
//= require prevent-double-submission
//
//= require adminre_theme_v120/plugins/shuffle/js/jquery.shuffle.min
//= require bootstrap-confirmation
//= require format
//= require js-routes
//= require tags
//= require departments
//= require parsley
//= require adminre_theme_v120/plugins/xeditable/js/bootstrap-editable
//= require adminre_theme_v120/plugins/switchery/js/switchery
//= require adminre_theme_v120/plugins/summernote/js/summernote
//= require jsvalidate-forms
//= require forms
//= require users
//= require alerts
//= require grid-search
//= require datatable-search
//= require items
//= require item_form
//= require items_import
//= require sparkline-graphs
//= require reports
//= require fax
//= require pusher
//= require notifications
//= require dashboard
//= require messaging
//= require budgets
//= require vendors
//= require vpt
//= require property-setting
//= require maintenance/room_selection
//= require maintenance/room_inspection
//= require maintenance/room_maintenance
//= require maintenance/room_inspect
//= require maintenance/room_setup
//= require maintenance/public_area_selection
//= require maintenance/public_area_inspection
//= require maintenance/public_area_inspect
//= require maintenance/equipment_setup
//= require maintenance/equipment_selection
//= require maintenance/equipment_maintenance
//= require maintenance/common
//= require maintenance/work_orders
//= require maintenance/dashboard
//= require jqcloud/jqcloud
//= require chrono.min
//= require guest_logs
//= require global-messages
//= require engage/dashboard
//= require global

//= require reports/date-range
//= require lodash.min
//= require lodash_mixins
//= require freshwidget
//= require stacked-bootstrap-modal

window.ParsleyConfig.errorsContainer = function(elm){
  return elm.$element.parent()
}

// adjust main section padding for mobile devices dynamically:
$main = $('#main'), $header = $('#header');
window.updatePadding = function () {
$.debounce(1000, function(){
  $main.css({ 'padding-top': $header.innerHeight() })
})()
}
window.onresize = window.updatePadding;
window.updatePadding()

$.fn.editable.defaults.ajaxOptions = {type: "PUT"};