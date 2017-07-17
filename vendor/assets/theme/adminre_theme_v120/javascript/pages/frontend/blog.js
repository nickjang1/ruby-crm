/*! ========================================================================
 * blog.js
 * Page/renders: page-blog-*.html
 * Plugins used: owl carousel, magnific
 * ======================================================================== */
$(function () {
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

    // Magnific popup
    // ================================
    $(".popup-vimeo").magnificPopup({
        disableOn: 700,
        type: "iframe",
        mainClass: "mfp-fade",
        removalDelay: 160,
        preloader: false,
        fixedContentPos: false
    });

    // Masonry
    // ================================
    $("#masonry").imagesLoaded(function () {
        $("#masonry").masonry({
            itemSelector: ".post",
            columnWidth: ".post"
        });
    });

    // relocate panel on window ready
    $(window).load(function () {
        $("#masonry").masonry("layout");
    });
});