/*! ========================================================================
 * dashboard-v2.js
 * Page/renders: index.html
 * Plugins used: flot, sparkline, owl carousel
 * ======================================================================== */
$(function () {
    // Stats Carousel
    // ================================
    (function () {
        $("#stats").owlCarousel({
            items: 4
        });
    })();

    // Stats
    // ================================
    (function () {
        // default options
        var option = {
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
        }

        // Stats #1
        $.plot("#stats1", [{
            color: "#DC554F",
            data: [ ["Mon", 5], ["Tue", 8], ["Wed", 15], ["Thu", 6], ["Fri", 10] ]
        }], option);

        // Stats #2
        $.plot("#stats2", [{
            color: "#3b5998",
            data: [ ["Mon", 6], ["Tue", 3], ["Wed", 16], ["Thu", 10], ["Fri", 6] ]
        }], option);

        // Stats #3
        $.plot("#stats3", [{
            color: "#6BCCB4",
            data: [ ["Mon", 16], ["Tue", 8], ["Wed", 6], ["Thu", 2], ["Fri", 4] ]
        }], option);

        // Stats #4
        $.plot("#stats4", [{
            color: "#00B1E1",
            data: [ ["Mon", 0], ["Tue", 16], ["Wed", 8], ["Thu", 6], ["Fri", 12] ]
        }], option);

        // Stats #5
        $.plot("#stats5", [{
            color: "#FFD66A",
            data: [ ["Mon", 2], ["Tue", 2], ["Wed", 4], ["Thu", 10], ["Fri", 16] ]
        }], option);
    })();

    // Column filtering
    // ================================
    (function () {
        var $table = $("table#order-list"),
            oTable = $table.dataTable({
            "aoColumns": [
                { "bSortable": false },
                null,
                null,
                null,
                null,
                null,
                null,
                null
            ],
            "oLanguage": {
                "sSearch": "Search all columns:"
            }
        });

        $table.on("keyup", "input[type=search]", function () {
            /* Filter on the column (the index) of this element */
            oTable.fnFilter(this.value, $("tfoot input").index(this));
        });
    })();

    // Markers on the world map
    // ================================
    (function () {
        $("#world-map-markers").vectorMap({
            map: "world_mill_en",
            backgroundColor: "#eee",
            scaleColors: ["#91C854", "#ED5466"],
            normalizeFunction: "polynomial",
            hoverOpacity: 0.7,
            hoverColor: false,
            markerStyle: {
                initial: {
                    fill: "#3b5998",
                    stroke: "#23355b"
                }
            },
            markers: [
                { latLng: [41.90, 12.45], name: "Vatican City" },
                { latLng: [43.73, 7.41], name: "Monaco" },
                { latLng: [-0.52, 166.93], name: "Nauru" },
                { latLng: [-8.51, 179.21], name: "Tuvalu" },
                { latLng: [43.93, 12.46], name: "San Marino" },
                { latLng: [47.14, 9.52], name: "Liechtenstein" },
                { latLng: [7.11, 171.06], name: "Marshall Islands" },
                { latLng: [17.3, -62.73], name: "Saint Kitts and Nevis" },
                { latLng: [3.2, 73.22], name: "Maldives" },
                { latLng: [35.88, 14.5], name: "Malta" },
                { latLng: [12.05, -61.75], name: "Grenada" },
                { latLng: [13.16, -61.23], name: "Saint Vincent and the Grenadines" },
                { latLng: [13.16, -59.55], name: "Barbados" },
                { latLng: [17.11, -61.85], name: "Antigua and Barbuda" },
                { latLng: [-4.61, 55.45], name: "Seychelles" },
                { latLng: [7.35, 134.46], name: "Palau" },
                { latLng: [42.5, 1.51], name: "Andorra" },
                { latLng: [14.01, -60.98], name: "Saint Lucia" },
                { latLng: [6.91, 158.18], name: "Federated States of Micronesia" },
                { latLng: [1.3, 103.8], name: "Singapore" },
                { latLng: [1.46, 173.03], name: "Kiribati" },
                { latLng: [-21.13, -175.2], name: "Tonga" },
                { latLng: [15.3, -61.38], name: "Dominica" },
                { latLng: [-20.2, 57.5], name: "Mauritius" },
                { latLng: [26.02, 50.55], name: "Bahrain" },
                { latLng: [0.33, 6.73], name: "São Tomé and Príncipe" }
            ]
        });
    })();
});