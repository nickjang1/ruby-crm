//= require adminre_theme_v120/library/jquery/js/jquery.min
//= require adminre_theme_v120/plugins/jqueryui/js/jquery-ui.min
//= require adminre_theme_v120/library/jquery/js/jquery-migrate.min
//= require jquery_ujs
//= require adminre_theme_v120/library/bootstrap/js/bootstrap
//= require adminre_theme_v120/library/core/js/core
//= require adminre_theme_v120/plugins/sparkline/js/jquery.sparkline
//= require adminre_theme_v120/javascript/app.js
//= require adminre_theme_v120/plugins/gritter/js/jquery.gritter
//= require bootstrap-confirmation
//= require jquery.ba-throttle-debounce
//= require js-routes
//= require jsvalidate-forms
//= require alerts
//= require parsley

//= require admin/customers

window.ParsleyConfig.errorsContainer = function(elm){
    return elm.$element.parent()
}

// adjust main section padding for mobile devices dynamically:
$(function(){
  $main = $('#main'), $header = $('#header');
  function updatePadding(){
    $.debounce(1000, function(){
      $main.css({ 'padding-top': $header.innerHeight() })
    })() 
  }
  window.onresize = updatePadding;
  updatePadding()
})
