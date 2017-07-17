/*! ========================================================================
 * register.js
 * Page/renders: page-register.html
 * Plugins used: parsley
 * ======================================================================== */
$(function () {
    // Register form function
    // ================================
    var $form    = $("form[name=form-register]");

    // On button submit click
    $form.on("click", "button[type=submit]", function (e) {
        var $this = $(this);

        // Run parsley validation
        if ($form.parsley().validate()) {
            // Disable submit button
            $this.prop("disabled", true);

            // start nprogress bar
            NProgress.start();

            // you can do the ajax request here
            // this is for demo purpose only
            setTimeout(function () {
                // done nprogress bar
                NProgress.done();

                // redirect user
                location.href = "page-login.html";
            }, 500);
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