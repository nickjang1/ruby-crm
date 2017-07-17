/*! ========================================================================
 * timeline.js
 * Page/renders: page-timeline.html
 * Plugins used: magnific-popup
 * ======================================================================== */
$(function () {
    // Magnific Popup
    // ================================
    $("#photo-list").magnificPopup({
        delegate: ".magnific",
        type: "image",
        gallery: {
            enabled: true
        }
    });
});