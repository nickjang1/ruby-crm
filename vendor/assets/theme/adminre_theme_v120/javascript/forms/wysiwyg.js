/*! ========================================================================
 * wysiwyg.js
 * Page/renders: forms-wysiwyg.html
 * Plugins used: summernote
 * ======================================================================== */
$(function () {
    // Summernote
    // ================================
    $(".summernote").summernote({
        height: 200,
        toolbar: [
            ["style", ["style"]],
            ["style", ["bold", "italic", "underline", "clear"]],
            ["fontsize", ["fontsize"]],
            ["color", ["color"]],
            ["para", ["ul", "ol", "paragraph"]],
            ["height", ["height"]],
            ["table", ["table"]]
        ]
    });
});