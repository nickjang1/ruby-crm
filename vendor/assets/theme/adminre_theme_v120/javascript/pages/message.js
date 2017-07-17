/*! ========================================================================
 * message.js
 * Page/renders: page-message.html
 * Plugins used: magnific-popup, gritter, selectize
 * ======================================================================== */
$(function () {
    // Gritter
    // ================================
    setTimeout(function () {
        $.gritter.add({
            title: "You have (14) unread message",
            text: "This will fade out after a certain amount of time. Vivamus eget tincidunt velit.",
            sticky: false
        });
    }, 3000);

    // Magnific Popup
    // ================================
    $("#photo-album").magnificPopup({
        delegate: ".magnific",
        type: "image",
        gallery: {
            enabled: true
        }
    });

    // Contact select
    // ================================
    (function () {
        var REGEX_EMAIL = "([a-z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*@" +
                "(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)";

        var formatName = function (item) {
            return $.trim((item.first_name || '') + ' ' + (item.last_name || ''));
        };
        // contact
        $("#selectize-contact").selectize({
            persist: false,
            maxItems: null,
            valueField: "email",
            labelField: "name",
            searchField: ["first_name", "last_name", "email"],
            sortField: [{
                field: "first_name",
                direction: "asc"
            }, {
                field: "last_name",
                direction: "asc"
            }],
            options: [{
                email: "nikola@tesla.com",
                first_name: "Nikola",
                last_name: "Tesla"
            }, {
                email: "brian@thirdroute.com",
                first_name: "Brian",
                last_name: "Reavis"
            }, {
                email: "pampersdry@gmail.com",
                first_name: "John",
                last_name: "Pozy"
            }],
            render: {
                item: function (item, escape) {
                    var name = formatName(item);
                    return "<div>" +
                        (name ? "<span class=\"name\">" + escape(name) + "</span>" : "") +
                        (item.email ? "<small class=\"text-muted ml10\">" + escape(item.email) + "</small>" : "") +
                        "</div>";
                },
                option: function (item, escape) {
                    var name = formatName(item);
                    var label = name || item.email;
                    var caption = name ? item.email : null;
                    return "<div>" +
                        "<span class=\"text-primary\">" + escape(label) + "</span><br/>" +
                        (caption ? "<small class=\"text-muted\">" + escape(caption) + "</small>" : "") +
                        "</div>";
                }
            },
            create: function (input) {
                if ((new RegExp("^" + REGEX_EMAIL + "$", "i")).test(input)) {
                    return {
                        email: input
                    };
                }
                var match = input.match(new RegExp("^([^<]*)\<" + REGEX_EMAIL + "\>$", "i"));
                if (match) {
                    var name = $.trim(match[1]);
                    var pos_space = name.indexOf(" ");
                    var first_name = name.substring(0, pos_space);
                    var last_name = name.substring(pos_space + 1);

                    return {
                        email: match[2],
                        first_name: first_name,
                        last_name: last_name
                    };
                }
                alert("Invalid email address.");
                return false;
            }
        });
    })();
});