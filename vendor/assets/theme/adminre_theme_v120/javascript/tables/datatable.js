/*! ========================================================================
 * datatable.js
 * Page/renders: table-datatable.html
 * Plugins used: datatable
 * ======================================================================== */
$(function () {
    // zero configuration
    // ================================
    $("#zero-configuration").dataTable();

    // ajax source
    $("#ajax-source").dataTable({
        "bProcessing": true,
        "sAjaxSource": "../server/datatable.php",
        "sServerMethod": "POST"
    });

    // table tools
    // ================================
    $("#table-tools").dataTable({
        "sDom": "<'row'<'col-sm-4'T><'col-sm-4'l><'col-sm-4'f>><'table-responsive'rt><'row'<'col-sm-6'p><'col-sm-6'i>>",
        "oTableTools": {
            "sSwfPath": "../plugins/datatables/tabletools/swf/copy_csv_xls_pdf.swf",
            "aButtons": [
                "copy",
                "print",
                "pdf",
                "csv"
            ]
        }
    });

    // row details
    // ================================
    (function () {
        // Formating function for row details
        var fnFormatDetails = function (oTable, nTr) {
            var sOut = "",
                aData = oTable.fnGetData(nTr);

            sOut += '<table class="table table-condensed nm">';
            sOut += '<tr><td width="15%">Rendering engine:</td><td>' + aData[1] + ' ' + aData[4] + '</td></tr>';
            sOut += '<tr><td width="15%">Link to source:</td><td>Could provide a link here</td></tr>';
            sOut += '<tr><td width="15%">Extra info:</td><td>And any further details here (images etc)</td></tr>';
            sOut += '</table>';

            return sOut;
        };

        var nCloneTh = document.createElement("th"),
            nCloneTd = document.createElement("td");
        nCloneTd.innerHTML = '<a href="#" class="text-primary detail-toggler" style="text-decoration:none;font-size:14px;"><i class="ico-plus-circle"></i></a>';
        nCloneTd.className = "center";

        $("#row-detail thead tr").each(function () {
            this.insertBefore(nCloneTh, this.childNodes[0]);
        });
        $("#row-detail tbody tr").each(function () {
            this.insertBefore(nCloneTd.cloneNode(true), this.childNodes[0]);
        });

        // Initialse DataTables
        var oTable = $("#row-detail").dataTable({
            "aoColumnDefs": [{
                "bSortable": false,
                "aTargets": [0]
            }],
            "aaSorting": [
                [1, "asc"]
            ]
        });

        // Add event listener for opening and closing details
        $("#row-detail tbody td .detail-toggler").on("click", function (e) {
            var nTr = $(this).parents("tr")[0];
            $(nTr).toggleClass("open");
            if (oTable.fnIsOpen(nTr)) {
                // This row is already open - close it
                $(this).children().attr("class", "ico-plus-circle");
                oTable.fnClose(nTr);
            } else {
                // Open this row
                $(this).children().attr("class", "ico-minus-circle");
                oTable.fnOpen(nTr, fnFormatDetails(oTable, nTr), "details np");
            }
            e.preventDefault();
        });
    })();

    // Column filtering
    // ================================
    (function () {
        var $table = $("table#column-filtering"),
            oTable = $table.dataTable({
            "oLanguage": {
                "sSearch": "Search all columns:"
            }
        });

        $table.on("keyup", "input[type=search]", function () {
            /* Filter on the column (the index) of this element */
            oTable.fnFilter(this.value, $("tfoot input").index(this));
        });
    })();
});