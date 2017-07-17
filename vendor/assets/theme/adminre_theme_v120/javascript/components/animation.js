/*! ========================================================================
 * animation.js
 * Page/renders: components-animation.html
 * Plugins used: 
 * ======================================================================== */
$(function () {
    // Toggle animation
    // ================================
    var anim,
        panel;

    // toggler
    $("body").on("click", ".btn-toggle-anim", function (e) {
        // get animation class and panel
        anim = $(this).data("anim");
        panel = $(this).parents(".panel");

        // add animation class to panel element
        panel
            .addClass("animation animating " + anim)
            .one("webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", function () {
                $(this).removeClass("animation animating " + anim);

            });
        e.preventDefault();
    });
});