/*! ========================================================================
 * carousel.js
 * Page/renders: components-carousel.html
 * Plugins used: owl carousel
 * ======================================================================== */
$(function () {
    // Carousel
    // ================================
    
    // default
    $("#default").owlCarousel();

    // autoplay
    $("#auto-play").owlCarousel({
        autoPlay: true
    });

    // lazy load
    $("#lazy-load").owlCarousel({
        lazyLoad : true
    });

    // one slide
    $("#one-slide").owlCarousel({
        navigation: true,
        singleItem: true
    });
});