/*! ========================================================================
 * media.js
 * Page/renders: page-media.html
 * Plugins used: shuffle, magnific-popup
 * ======================================================================== */
$(function () {
    // Lightbox
    // ================================
    $("#shuffle-grid").magnificPopup({
        delegate: ".magnific",
        type: "image",
        gallery: {
            enabled: true
        }
    });

    // Carousel
    // ================================
    $("#lovely-client").owlCarousel({
        autoPlay: true,
        autoHeight : true,
        pagination : true
    });

    // Owl carousel
    // ================================
    $("#gallery-post").owlCarousel({
        lazyLoad: true,
        slideSpeed: 300,
        paginationSpeed: 400,
        singleItem: true,
        autoPlay: true,
        stopOnHover: true,
        navigation: true,
        pagination: false
    });

    // Shuffle
    // ================================
    var $grid   = $("#shuffle-grid"),
        $filter = $("#shuffle-filter"),
        $sort   = $("#shuffle-sort"),
        $sizer  = $grid.find("shuffle-sizer");
    
    // instatiate shuffle
    $grid.shuffle({
        itemSelector: ".shuffle",
        sizer: $sizer
    });

    // Filter options
    (function () {
        $filter.on("click", ".btn", function () {
            var $this = $(this),
                isActive = $this.hasClass("active"),
                group = isActive ? "all" : $this.data("group");

            // Hide current label, show current label in title
            if (!isActive) {
                $("#shuffle-filter .active").removeClass("active");
            }

            $this.toggleClass("active");

            // Filter elements
            $grid.shuffle("shuffle", group);
        });
    })();

    // Sorting options
    (function () {
        $sort.on("change", function () {
            var sort = this.value,
                opts = {};

            // We're given the element wrapped in jQuery
            if (sort === "date-created") {
                opts = {
                    reverse: true,
                    by: function ($el) {
                        return $el.data("date-created");
                    }
                };
            } else if (sort === "title") {
                opts = {
                    by: function ($el) {
                        return $el.data("title").toLowerCase();
                    }
                };
            }

            // Filter elements
            $grid.shuffle("sort", opts);
        });
    })();
});