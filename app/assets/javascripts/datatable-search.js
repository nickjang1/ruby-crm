/*! ========================================================================
 * see: grid-search.js and people.js
 * Page/renders: all pages with datatable seach
 * Plugins used: datatable
 * ======================================================================== */
jQuery(document).ready(function() {
    var $table   = $(".searchable-table"),
        $filter = $("#datatable-filter");
    

    $filter.on("keyup change", function () {
      var val = this.value.toLowerCase();
      $table.dataTable().fnFilter(val);
    });
});
