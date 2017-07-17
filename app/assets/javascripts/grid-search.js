/*! ========================================================================
 * see: people.js
 * Page/renders: all pages with shuffle filter search on cards
 * Plugins used: shuffle
 * ======================================================================== */
jQuery(document).ready(function() {
    // Shuffle
    // ================================
    var $grid   = $("#shuffle-grid"),
        $filterOptions = $("#filter-options"),
        $filter = $("#shuffle-filter"),
        $sizer  = $grid.find("shuffle").first();
    
    // instatiate shuffle
    $grid.shuffle({
        itemSelector: ".shuffle",
        sizer: $sizer
    });

    //Filter
    (function() {
        var $btns = $filterOptions.children();
        $btns.on('click', function() {
          var $this = $(this),
              isActive = $this.hasClass( 'active' ),
              group = isActive ? 'all' : $this.data('group');

          $filterOptions.find('.active').removeClass('active');

          $this.toggleClass('active');

          // Filter elements
          $grid.shuffle( 'shuffle', group );
        });

        $btns = null;
      })();

    // search
    (function() {
        $filter.on("keyup change", function () {
            var val = this.value.toLowerCase();
            $grid.shuffle("shuffle", function ($el, shuffle) {

                // Only search elements in the current group
                if (shuffle.group !== "all" && $.inArray(shuffle.group, $el.data("groups")) === -1) {
                    return false;
                }

                var text = $.trim($el.find(".panel-body .search-target").text()).toLowerCase();
                return text.indexOf(val) !== -1;
            });
        });
    })();

    // Update shuffle on sidebar minimize/maximize
    $("html")
        .on("fa.sidebar.minimize", function () { $grid.shuffle("update"); })
        .on("fa.sidebar.maximize", function () { $grid.shuffle("update"); });

    $grid.imagesLoaded(function(){
      $grid.shuffle('layout');
    });
});
