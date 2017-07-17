/*! ========================================================================
 * google.js
 * Page/renders: maps-google.html
 * Plugins used: gmaps
 * ======================================================================== */
$(function () {
    // gmaps - basic
    // ================================
    basic = new GMaps({
        el: "#gmaps-basic",
        lat: -12.043333,
        lng: -77.028333,
        zoomControl : true,
        zoomControlOpt: {
            style : "SMALL",
            position: "TOP_LEFT"
        },
        panControl : false,
        streetViewControl : false,
        mapTypeControl: false,
        overviewMapControl: false
    });

    // gmaps - marker
    // ================================
    marker = new GMaps({
        el: "#gmaps-marker",
        lat: -12.043333,
        lng: -77.028333
    });
    marker.addMarker({
        lat: -12.043333,
        lng: -77.03,
        title: "Lima",
        details: {
            database_id: 42,
            author: "HPNeo"
        },
        click: function(e){
            alert('You clicked in this marker');
        }
    });
    marker.addMarker({
        lat: -12.042,
        lng: -77.028333,
        title: "Marker with InfoWindow",
        infoWindow: {
            content: '<p>HTML Content</p>'
        }
    });

    // gmaps - geolocation
    // ================================
    var geolocation = new GMaps({
        el: "#gmaps-geolocation",
        lat: -12.043333,
        lng: -77.028333
    });

    GMaps.geolocate({
        success: function(position) {
            geolocation.setCenter(position.coords.latitude, position.coords.longitude);
        },
        error: function(error) {
            console.log('Geolocation failed: '+error.message);
        },
        not_supported: function() {
            console.log("Your browser does not support geolocation");
        },
        always: function(){
            console.log("Done!");
        }
    });

    // gmaps - geocoding
    // ================================
    var geocoding = new GMaps({
        el: "#gmaps-geocoding",
        lat: -12.043333,
        lng: -77.028333
    });
    $("#geocoding-form").submit(function(e) {
        e.preventDefault();
        GMaps.geocode({
            address: $("#geocoding-address").val().trim(),
            callback: function(results, status){
                if(status=="OK"){
                    var latlng = results[0].geometry.location;
                    geocoding.setCenter(latlng.lat(), latlng.lng());
                    geocoding.addMarker({
                        lat: latlng.lat(),
                        lng: latlng.lng()
                    });
                }
            }
        });
    });

    // gmaps - routes
    // ================================
    var routes = new GMaps({
        el: "#gmaps-routes",
        lat: -12.043333,
        lng: -77.028333
    });

    $("#start-routes").on("click", function (e) {
        routes.travelRoute({
            origin: [-12.044012922866312, -77.02470665341184],
            destination: [-12.090814532191756, -77.02271108990476],
            travelMode: "driving",
            step: function(e){
                $("#gmaps-routes-inst").append('<li>'+e.instructions+'</li>');
                $("#gmaps-routes-inst li:eq("+e.step_number+")").delay(450*e.step_number).fadeIn(200, function(){
                    routes.drawPolyline({
                        path: e.path,
                        strokeColor: "#131540",
                        strokeOpacity: 0.6,
                        strokeWeight: 6
                    });  
                });
            }
        });

        // prevent default
        e.preventDefault();
    });
});