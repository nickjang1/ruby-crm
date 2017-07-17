/*! ========================================================================
 * notification.js
 * Page/renders: components-notification.html
 * Plugins used: gritter, bootbox
 * ======================================================================== */
$(function () {
    // Gritter
    // ================================
    (function () {
        // sticky notice
        $("#add-sticky").on("click", function (e) {
            $.gritter.add({
                title: "Sticky notice",
                text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget tincidunt velit.",
                sticky: true,
            });
            e.preventDefault();
        });

        // regular notice
        $("#add-regular").on("click", function (e) {
            $.gritter.add({
                title: "Regular notice",
                text: "This will fade out after a certain amount of time. Vivamus eget tincidunt velit.",
                sticky: false,
            });
            e.preventDefault();
        });

        // max 3 notice
        $("#add-max").on("click", function (e) {
            $.gritter.add({
                title: "Max of 3 notice on screen",
                text: "This will fade out after a certain amount of time. Vivamus eget tincidunt velit.",
                sticky: false,
                // (function) before the gritter notice is opened
                before_open: function () {
                    if ($(".gritter-item-wrapper").length == 3) {
                        // Returning false prevents a new gritter from opening
                        return false;
                    }
                }
            });
            e.preventDefault();
        });

        // with image notice
        $("#add-image").on("click", function (e) {
            $.gritter.add({
                title: "Notice with image",
                text: "This will fade out after a certain amount of time. Vivamus eget tincidunt velit.",
                image: "../assets/image/avatar/avatar5.jpg",
                sticky: false
            });
            e.preventDefault();
        });

        // light notice with image
        $("#add-light").on("click", function (e) {
            $.gritter.add({
                title: "Light notice",
                text: "This will fade out after a certain amount of time. Vivamus eget tincidunt velit.",
                image: "../assets/image/avatar/avatar8.jpg",
                class_name: "gritter-light",
                sticky: true
            });
            e.preventDefault();
        });
    })();

    // Bootbox
    // ================================
    (function () {
        // bootbox - alert
        $("#bootbox-alert").on("click", function (event) {
            bootbox.alert("Hello world!");
            event.preventDefault();
        });

        // bootbox - confirm
        $("#bootbox-confirm").on("click", function (event) {
            bootbox.confirm("Are you sure?", function (result) {
                // callback
            });
            event.preventDefault();
        });

        // bootbox - prompt
        $("#bootbox-prompt").on("click", function (event) {
            bootbox.prompt("What is your name?", function (result) {
                // callback
            });
            event.preventDefault();
        });

        // bootbox - custom
        $("#bootbox-custom").on("click", function (event) {
            bootbox.dialog({
                message: "I am a custom dialog",
                title: "Custom title",
                buttons: {
                    success: {
                        label: "Success",
                        className: "btn-success",
                        callback: function () {
                            // callback
                        }
                    },
                    danger: {
                        label: "Danger",
                        className: "btn-danger",
                        callback: function () {
                            // callback
                        }
                    },
                    main: {
                        label: "Primary",
                        className: "btn-primary",
                        callback: function () {
                            // callback
                        }
                    }
                }
            });
            event.preventDefault();
        });
    })();
});