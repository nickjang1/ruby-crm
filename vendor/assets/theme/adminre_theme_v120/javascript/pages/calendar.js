/*! ========================================================================
 * calendar.js
 * Page/renders: page-calendar.html
 * Plugins used: parsley, fullcalendar, jQuery UI
 * ======================================================================== */
$(function () {
    // Instantiate fullCalendar
    // ================================
    var date = new Date(),
        d = date.getDate(),
        m = date.getMonth(),
        y = date.getFullYear();

    $("#full_calendar").fullCalendar({
        header: {
            left: "prev,next",
            center: "title",
            right: "today,month,agendaWeek,agendaDay"
        },
        buttonText: {
            prev: "<",
            next: ">"
        },
        editable: true,
        events: [{
            title: "All Day Event",
            start: new Date(y, m, 1),
            className: "fc-event-primary"
        }, {
            title: "Click me!.. seriously",
            start: new Date(y, m, d - 5),
            end: new Date(y, m, d - 2),
            className: "fc-event-success"
        }, {
            id: 999,
            title: "Repeating Event",
            start: new Date(y, m, d - 3, 16, 0),
            allDay: false,
            className: "fc-event-info"
        }, {
            id: 999,
            title: "Repeating Event",
            start: new Date(y, m, d + 4, 16, 0),
            allDay: false,
            className: "fc-event-warning"
        }, {
            title: "Meeting",
            start: new Date(y, m, d, 10, 30),
            allDay: false,
            className: "fc-event-danger"
        }, {
            title: "Lunch",
            start: new Date(y, m, d, 12, 0),
            end: new Date(y, m, d, 14, 0),
            allDay: false,
            className: "fc-event-inverse"
        }, {
            title: "Birthday Party",
            start: new Date(y, m, d + 1, 19, 0),
            end: new Date(y, m, d + 1, 22, 30),
            allDay: false
        }, {
            title: "Click for Google",
            start: new Date(y, m, 28),
            end: new Date(y, m, 29),
            url: "http://google.com/",
            className: "fc-event-teal"
        }],
        eventClick: function (calEvent, jsEvent, view) {
            // content
            var pcontent = "";
            pcontent += "<h5 class=semibold>";
            pcontent += "<img class='mr10' src='../image/icons/bloggingservices.png' width='42' height='42' />";
            pcontent += calEvent.title;
            pcontent += "</h5>";
            pcontent += "<hr/>";
            pcontent += "<p class=''><span class='ico-clock'></span> Start: ";
            pcontent += $.fullCalendar.moment(calEvent.start).format();
            pcontent += "</p>";
            if (calEvent.end !== null) {
                pcontent += "<p class=''><span class='ico-clock'></span>  End: ";
                pcontent += $.fullCalendar.moment(calEvent.end).format();
                pcontent += "</p>";
            }

            // bootstrap popover
            $(this).popover({
                placement: "left auto",
                html: true,
                trigger: "manual",
                content: pcontent
            }).popover("toggle");
        }
    });

    // Instantiate parsley validator
    // ================================
    $("#ModalAddEvent form").parsley();
    $("#ModalAddEvent form").on("submit", function (e) {
        e.preventDefault()
    });

    // Render Full Calendar event
    // ================================
    $("#ModalAddEvent form").on("click", "button[type=submit]", renderEvent);

    // core render function
    function renderEvent (e) {
        // validate using parsley validator
        if($("#ModalAddEvent form").parsley().validate()) {
            // collect render data
            var eventData = {
                id: 999,
                title: $("input[name=eventname]").val(),
                start: $.fullCalendar.moment($("input[name=datefrom]").val()),
                end: $.fullCalendar.moment($("input[name=dateto]").val()),
                allDay: $("select[name=allday]").val() === "yes" ? true : false,
                className: "fc-event-" + $("input[name=eventcolor]:checked").val()
            }

            // render event
            $("#full_calendar").fullCalendar("renderEvent", eventData, true);

            // and then push data to server ;)

            // close modal
            $("#ModalAddEvent").modal("hide");
        }
    }

    // rerender calender on sidebar 
    // minimize and maximize
    // ================================
    $("html")
        .on("fa.sidebar.minimize", function (e) { $("#full_calendar").fullCalendar("render") })
        .on("fa.sidebar.maximize", function (e) { $("#full_calendar").fullCalendar("render") });

    // Instantiate Datepicker
    // ================================
    $("#datepicker-from").datepicker({
        defaultDate: "+1w",
        onClose: function (selectedDate) {
            $("#datepicker-to").datepicker("option", "minDate", selectedDate);
        }
    });
    $("#datepicker-to").datepicker({
        defaultDate: "+1w",
        onClose: function (selectedDate) {
            $("#datepicker-from").datepicker("option", "maxDate", selectedDate);
        }
    });
});