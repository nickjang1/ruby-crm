/*! ========================================================================
 * element.js
 * Page/renders: forms-element.html
 * Plugins used: selectize
 * ======================================================================== */
$(function () {
    // custom select
    // ================================
    $("#selectize-customselect").selectize();

    // tagging
    // ================================
    $("#selectize-tagging").selectize({
        delimiter: ",",
        persist: false,
        create: function (input) {
            return {
                value: input,
                text: input
            }
        }
    });

    // select
    // ================================
    $("#selectize-select").selectize({
        create: true,
        sortField: {
            field: "text",
            direction: "asc"
        },
        dropdownParent: "body"
    });

    // multiple select
    // ================================
    $("#selectize-selectmultiple").selectize({
        maxItems: 3
    });

    // Contact style
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

    // Datepicker
    // ================================
    // default
    $("#datepicker1").datepicker();

    // date in other moonth
    $("#datepicker2").datepicker({
        showOtherMonths: true,
        selectOtherMonths: true
    });

    // button bar
    $("#datepicker3").datepicker({
        showButtonPanel: true
    });

    // display month & year
    $("#datepicker4").datepicker({
        changeMonth: true,
        changeYear: true
    });

    // select date range
    $("#datepicker-from").datepicker({
        defaultDate: "+1w",
        numberOfMonths: 2,
        onClose: function (selectedDate) {
            $("#datepicker-to").datepicker("option", "minDate", selectedDate);
        }
    });
    $("#datepicker-to").datepicker({
        defaultDate: "+1w",
        numberOfMonths: 2,
        onClose: function (selectedDate) {
            $("#datepicker-from").datepicker("option", "maxDate", selectedDate);
        }
    });

    // Timepicker
    // ================================
    // datepicker + timepicker
    $("#datetime-picker").datetimepicker();

    // timepicker only
    $("#time-picker").timepicker();

    // timepicker time format
    $("#time-picker-format").timepicker({
        timeFormat: "hh:mm:ss tt"
    });

    // timepicker timezone
    $("#time-picker-timezone").timepicker({
        timeFormat: "hh:mm:ss tt z"
    });
});