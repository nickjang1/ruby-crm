/*! ========================================================================
 * login.js
 * Page/renders: page-login.html
 * Plugins used: parsley
 * ======================================================================== */
$(function () {
    // Login form function
    // ================================
    var $form    = $("form[name=form-login]");

    // On button submit click
    $form.on("click", "input[type=submit]", function (e) {
        var $this = $(this);

        // Run parsley validation
        if ($form.parsley().validate()) {
            // Disable submit button
            $this.prop("disabled", true);
            $form.submit();
        } else {
            // toggle animation
            $form
                .removeClass("animation animating shake")
                .addClass("animation animating shake")
                .one("webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", function () {
                    $(this).removeClass("animation animating shake");
                });
        }
        // prevent default
        e.preventDefault();
    });
});
