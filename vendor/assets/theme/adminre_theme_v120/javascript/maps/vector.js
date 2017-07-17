/*! ========================================================================
 * vector.js
 * Page/renders: maps-vector.html
 * Plugins used: jvectormap
 * ======================================================================== */
$(function () {
    // GDP by country visualization
    // ================================
    (function () {
        $("#world-map-gdp").vectorMap({
            map: "world_mill_en",
            backgroundColor: "#444",
            series: {
                regions: [{
                    values: gdpData,
                    scale: ["#00B1E1", "#91C854"],
                    normalizeFunction: "polynomial"
                }]
            },
            onLabelShow: function(e, el, code){
                el.html(el.html()+' (GDP - '+gdpData[code]+')');
            }
        });
    })();

    // Markers on the world map
    // ================================
    (function () {
        $("#world-map-markers").vectorMap({
            map: "world_mill_en",
            backgroundColor: "#444",
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
    
    // Region selection
    // ================================
    (function () {
        var region,
            markers = [
                { latLng: [52.50, 13.39], name: 'Berlin' }, 
                { latLng: [53.56, 10.00], name: 'Hamburg' }, 
                { latLng: [48.13, 11.56], name: 'Munich' }, 
                { latLng: [50.95, 6.96], name: 'Cologne' }, 
                { latLng: [50.11, 8.68], name: 'Frankfurt am Main' }, 
                { latLng: [48.77, 9.17], name: 'Stuttgart' }, 
                { latLng: [51.23, 6.78], name: 'Düsseldorf' }, 
                { latLng: [51.51, 7.46], name: 'Dortmund' }, 
                { latLng: [51.45, 7.01], name: 'Essen' }, 
                { latLng: [53.07, 8.80], name: 'Bremen' }
            ],
            cityAreaData = [ 887.70, 755.16, 310.69, 405.17, 248.31, 207.35, 217.22, 280.71, 210.32, 325.42 ];

        region = new jvm.WorldMap({
            container: $("#region-selection"),
            map: "de_merc_en",
            backgroundColor: "#444",
            regionsSelectable: true,
            markersSelectable: true,
            markers: markers,
            markerStyle: {
                initial: {
                    fill: "#55acee"
                },
                selected: {
                    fill: "#3b5998"
                }
            },
            regionStyle: {
                initial: {
                    fill: "#91C854"
                },
                selected: {
                    fill: "#FFD66A"
                }
            },
            series: {
                markers: [{
                    attribute: "r",
                    scale: [5, 15],
                    values: cityAreaData
                }]
            },
            onRegionSelected: function () {
                if (window.localStorage) {
                    window.localStorage.setItem(
                        "jvectormap-selected-regions",
                        JSON.stringify(region.getSelectedRegions())
                    );
                }
            },
            onMarkerSelected: function () {
                if (window.localStorage) {
                    window.localStorage.setItem(
                        "jvectormap-selected-markers",
                        JSON.stringify(region.getSelectedMarkers())
                    );
                }
            }
        });
        region.setSelectedRegions(JSON.parse(window.localStorage.getItem("jvectormap-selected-regions") || "[]"));
        region.setSelectedMarkers(JSON.parse(window.localStorage.getItem("jvectormap-selected-markers") || "[]"));
    })();

    // Random colors
    // ================================
    (function () {
        var palette = ["#00B6AD", "#00B1E1", "#91C854", "#FFD66A", "#ED5466"],
        generateColors = function(){
            var colors = {},
                key;

            for (key in map.regions) {
                colors[key] = palette[Math.floor(Math.random()*palette.length)];
            }
            return colors;
        },
        map;

        map = new jvm.WorldMap({
            map: "es_merc_en",
            container: $("#random-colors"),
            series: {
                regions: [{
                    attribute: "fill"
                }]
            }
        });
        map.series.regions[0].setValues(generateColors());
        $("#update-colors-button").on("click", function (e) {
            e.preventDefault();
            map.series.regions[0].setValues(generateColors());
        });
    })();
});