//
// Author: Pierre Lebrun
// Email: anthonylebrun@gmail.com
// Company: SmashingBoxes (http://smashingboxes.com)
//

;(function($) {

  var CheckableTableRow = {
    defaults: {
      inactivateLinkSelector: undefined,
      ignoreLinksSelector: undefined,
      checkedClass: "active"
    }
  };

  /********************/
  /* Plugin Interface */
  /********************/

  CheckableTableRow.publicMethods = {

    initialize: function(options) {
      return this.each(function() {
        var $this = $(this);

        if ($this.data('checkedtablerow') == null) {          
          var checkedtablerow = $.extend({}, CheckableTableRow.privateMethods);
          var settings = $.extend({}, CheckableTableRow.defaults, options || {});
          checkedtablerow.initialize(this, settings);
          $this.data('checkedtablerow', checkedtablerow);
        }
      });
    }
  };

  /******************************/
  /* Private (instance) methods */
  /******************************/

  CheckableTableRow.privateMethods = {

    initialize: function(el, settings) {
      this.$el = $(el);  
      this.$tableRows = this.$el.find('tbody tr');
      this.$rowCheckBoxes = this.$tableRows.find('input[type=checkbox]');
      

      this.$rowCheckBoxes.change(function(e) {
        $checkbox = e.target;
        $row = $checkbox.parent('tr');

        if($checkbox.checked) {
          $tr.addClass(settings.checkedClass);
        } else {
          $tr.removeClass(settings.checkedClass);
        }
      });

      this.$tableRows.click(function(e){
        $tr = $(this);
        $checkbox = $(this).find('input[type=checkbox]');

        // disable links that are just there for show
        if ($tr.find(settings.inactiveLinkSelector).has(e.target).length) {
          e.preventDefault();
        }
        
        // prevent useful links from clicking the tr through propagation
        if ($tr.find(settings.ignoreLinksSelector).has(e.target).length) {
          return true;
        }
        
        if ($tr.hasClass(settings.checkedClass)) {
          $checkbox.prop('checked', false);
          $tr.removeClass(settings.checkedClass);
        } else {
          $checkbox.prop('checked', true);
          $tr.addClass(settings.checkedClass);
        }
      });
    }
  };

  /*******************************/
  /* wrapping it all in a plugin */
  /*******************************/

  $.fn.checkedTableRow = function(method) {
    if (CheckableTableRow.publicMethods[method]) {
      return CheckableTableRow.publicMethods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else if (typeof method === 'object' || !method) {
      return CheckableTableRow.publicMethods.initialize.apply(this, arguments);
    } else {
      $.error('Method ' + method + ' does not exist on jQuery.splitdropbutton');
    }
  };

})($);
