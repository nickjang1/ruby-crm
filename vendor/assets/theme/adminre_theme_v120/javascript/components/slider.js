/*! ========================================================================
 * slider.js
 * Page/renders: components-slider.html
 * Plugins used: jQuery UI 
 * ======================================================================== */
$(function () {
    // Default slider
    // ================================
    $("#default-slider > li").each(function () {
        $(this).slider({
            value: $(this).data("min"),
            orientation: "horizontal",
            range: "min",
            animate: true
        });
    });

    // Range slider
    // ================================
    $("#range-slider > li").each(function () {
        $(this).slider({
            range: true,
            min: 0,
            max: 100,
            values: [$(this).data("min"), $(this).data("max")]
        });
    });

    // Range slider - fix maximum
    // ================================
    $("#fixed-max-slider").slider({
        range: "max",
        min: 1,
        max: 10,
        value: 2,
        slide: function (event, ui) {
            $("#amount-max-slider").text(ui.value);
        }
    });
    $("#amount-max-slider").text($("#fixed-max-slider").slider("value"));

    // Range slider - fix minimum
    // ================================
    $("#fixed-min-slider").slider({
        range: "min",
        value: 37,
        min: 1,
        max: 700,
        slide: function (event, ui) {
            $("#amount-min-slider").text(ui.value);
        }
    });
    $("#amount-min-slider").text($("#fixed-min-slider").slider("value"));

    // Snap to increments
    // ================================
    $("#snap-increment-slider").slider({
        value: 100,
        min: 0,
        max: 500,
        step: 50,
        slide: function (event, ui) {
            $("#amount-snap-increment-slider").text("$" + ui.value);
        }
    });
    $("#amount-snap-increment-slider").text("$" + $("#snap-increment-slider").slider("value"));

    // Vertical slider
    // ================================
    $("#vertical-slider > li").each(function () {
        $(this).slider({
            orientation: "vertical",
            range: "min",
            min: 0,
            max: 100,
            value: $(this).data("min")
        });
    });

    // Vertical range slider
    // ================================
    $("#vertical-range-slider > li").each(function () {
        $(this).slider({
            orientation: "vertical",
            range: true,
            values: [$(this).data("min"), $(this).data("max")]
        });
    });
});