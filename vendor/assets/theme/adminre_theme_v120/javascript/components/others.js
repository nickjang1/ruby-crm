/*! ========================================================================
 * others.js
 * Page/renders: components-others.html
 * Plugins used: switchery
 * ======================================================================== */
$(function () {
    // Default checked
    // ================================
    (function () {
        var elem = document.querySelector(".switchery");
        var init = new Switchery(elem);
    })();

    // Multiple switches
    // ================================
    (function () {
        var elems = Array.prototype.slice.call(document.querySelectorAll(".multiple-switchery"));
        elems.forEach(function(html) {
            var switchery = new Switchery(html);
        });
    })();

    // Color variation
    // ================================
    (function () {
        var elems = Array.prototype.slice.call(document.querySelectorAll(".switchery-colored"));
        elems.forEach(function(html) {
            var color = $(html).data("switchery-color");
            var switchery = new Switchery(html, { color: color });
        });
    })();
});