/*! ========================================================================
 * default.js
 * Page/renders: table-default.html
 * Plugins used: sparkline
 * ======================================================================== */
$(function () {
    // Sparkline
    // ================================
    $(".sparklines").sparkline("html", {
        enableTagOptions: true
    });

    // Table toolbar
    // ================================
    (function () {
        // globar variable within this function scope
        var panel       = ".panel#toolbar-showcase",
            count       = 0;

        // subscribe to `selected` row event
        $(document).on("fa.selectrow.selected", function (event, data) {
            // define variable
            var $panel   = data.element.parents(panel),
                $toolbar = $panel.find("#toolbar-toshow");

            // check for the count panel #toolbar-showcase only
            // as we dont want the event affect other panel/table
            if( $panel.length > 0 ) {
                // total the count variable
                count = count + 1;

                // check for the count panel #toolbar-showcase only
                if( count === 1 ) {
                    $toolbar.removeClass("hide");
                }
            }
        });

        // subscribe to `unselected` row event
        $(document).on("fa.selectrow.unselected", function (event, data) {
            // define variable
            var $panel   = data.element.parents(panel),
                $toolbar = $panel.find("#toolbar-toshow");

            // check for the count panel #toolbar-showcase only
            // as we dont want the event affect other panel/table
            if( $panel.length > 0 ) {
                // minus the count variable
                count = count - 1;

                // check for the count
                if( count === 0 ) {
                    $toolbar.addClass("hide");
                }
            }
        });
    })();
});