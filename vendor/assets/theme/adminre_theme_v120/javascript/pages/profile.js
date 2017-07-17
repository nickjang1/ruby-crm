/*! ========================================================================
 * profile.js
 * Page/renders: page-profile.html
 * Plugins used: 
 * ======================================================================== */
$(function () {
    // Form submit sample
    // ================================
    var $form = $("form");

    // event handler
    $form.on("click", "button[type=submit]", submitForm);

    // submitForm function
    function submitForm (e) {

    	// start nprogress
    	NProgress.start();

    	// stop nprogress after 5sec
    	setTimeout(function () {
    		NProgress.done();
    	}, 5000);

    	// prevent default
    	e.preventDefault();
    }
});