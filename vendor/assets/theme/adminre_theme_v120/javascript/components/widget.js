/*! ========================================================================
 * widget.js
 * Page/renders: components-widget.html
 * Plugins used: flot, owl carousel
 * ======================================================================== */
$(function () {
    // Visitor widget chart
    // ================================
    $.plot("#visitor-wchart", [{
        color: "rgba(255, 255, 255, 0.5)",
        data: [ [0, 0], [1, 0], [2, 1], [3, 2], [4, 15], [5, 5], [6, 12] ]
    }], {
        series: {
            lines: { show: false },
            splines: {
                show: true,
                tension: 0.4,
                lineWidth: 2,
                fill: 0.5
            },
            points: {
                show: true,
                fill: true,
                radius: 4
            }
        },
        grid: {
            borderColor: "rgba(255, 255, 255, 0.15)",
            borderWidth: 1,
            hoverable: true,
            backgroundColor: "transparent"
        },
        xaxis: { tickColor: "transparent" },
        yaxis: { tickColor: "rgba(255, 255, 255, 0.15)" },
        shadowSize: 0
    });

    // Violations widget chart
    // ================================
    $.plot("#violations-wchart", [{
        color: "#DC554F",
        data: [ ["Jan", 35], ["Feb", 134], ["Mar", 85], ["Apr", 63], ["May", 96], ["Jun", 30], ["Jul", 61] ]
    }], {
        series: {
            lines: { show: false },
            splines: {
                show: true,
                tension: 0.4,
                lineWidth: 2,
                fill: 0.5
            },
            points: {
                show: true,
                radius: 4
            }
        },
        grid: {
            borderColor: "#eee",
            borderWidth: 1,
            hoverable: true,
            backgroundColor: "#fcfcfc"
        },
        tooltip: true,
        tooltipOpts: { content: "%x : %y" },
        xaxis: {
            tickColor: "#fcfcfc",
            mode: "categories"
        },
        yaxis: { tickColor: "#eee" },
        shadowSize: 0
    });

    // Carousel
    // ================================
    $("#carousel1").owlCarousel({
        navigation: true,
        singleItem: true
    });
});