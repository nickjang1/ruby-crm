/*! ========================================================================
 * ajax.js
 * Page/renders: forms-ajax.html
 * 
 * NOTE: in this demo i'll use bootstrap alert component to display the 
 * done/fail message. You can always use any other notification components 
 * like modal or gritter to display the message to the users ;)
 * ======================================================================== */
$(function () {
    // On success / done
    // ================================
    $("html").on("fa.formajax.done", function (event, data) {
        // construct bootstrap alert with some css animation
        var bsalert = '';
            bsalert += '<div class="alert alert-success animation animating flipInX">';
            bsalert += '<button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>';
            bsalert += '<h4 class="semibold mb5">Success!</h4>';
            bsalert += '<p class="nm">'+data.response.text+'</p>';
            bsalert += '</div>';

        // append to affected form
        data.element
            .find(".message-container")
            .html(bsalert);
    });

    // On fail / error
    // ================================
    $("html").on("fa.formajax.fail", function (event, data) {
        // define some variable
        var bsalert = '', 
            message;

        // construct message base on status code
        switch (data.response.status) {
            case 404:
                message = "The requested file is not found!";
            break;
            case 500:
                message = "Internal server / script error!";
            break;
        }
        // construct bootstrap alert with some css animation
        bsalert += '<div class="alert alert-danger animation animating flipInX">';
        bsalert += '<button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>';
        bsalert += '<h4 class="semibold mb5">'+data.response.status+' error!</h4>';
        bsalert += '<p class="nm">'+message+'</p>';
        bsalert += '</div>';

        // append to affected form
        data.element
            .find(".message-container")
            .html(bsalert);
    });
});