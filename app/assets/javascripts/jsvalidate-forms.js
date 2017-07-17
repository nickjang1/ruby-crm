
/*! ========================================================================
 * jsvalidate-forms.js
 * Plugins used: parsley
 * See: adminre_theme_v120/javascript/pages/login.js
 * ======================================================================== */
$(function () {
    // Login form function
    // ================================
    var $form    = $("form.jsvalidate");
    // On button submit click
    $form.on("click", "input[type=submit]", function (e) {
        var $this = $(this);
        // Run parsley validation
        if ($form.parsley({
                      errorsContainer: function ( elem ) {
                          return $( elem.$element ).parent();
                      }
                  })
                 .validate()) {
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
