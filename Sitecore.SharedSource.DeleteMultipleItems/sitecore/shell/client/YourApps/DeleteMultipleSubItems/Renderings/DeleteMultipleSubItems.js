define(["sitecore"], function (Sitecore) {
    var model = Sitecore.Definitions.Models.ControlModel.extend({
        initialize: function (options) {
            this._super();
            app = this;
            app.set("subitems", '');
            app.set("databases", '');
            $('.deleteTableHeader').hide();
            app.GetAllDatabases(app);
        },
        GetAllDatabases: function (app) {
            jQuery.ajax({
                type: "GET",
                dataType: "json",
                url: "/api/sitecore/DeleteMultipleItems/GetDatabase",
                cache: false,
                success: function (data) {
                    if (data.length > 1) {
                        $('#selectDatabases').show();
                        $('#selectDatabases').append($('<option>', {
                            value: data[1].Value,
                            text: data[1].Value
                        }));
                    }
                    else if (data.length == 1 && data[0].Value == false) {
                        $('#selectDatabases').hide();
                        $('.topHeader').hide();
                        $('.noresultfound').html('<h2>You are not an authorized user</h2>');
                        $('.noresultfound').show();
                    }
                    else {
                        $('#selectDatabases').hide();
                        $('.topHeader').hide();
                        $('.noresultfound').html('<h2>Some error occurred!</h2>');
                        $('.noresultfound').show();
                    }
                }
            });
        },
        GetSubItems: function (app) {
            var parentItemID = $('#txtParentItemId').val();
            var templateID = $('#txtTemplateId').val();
            var selectedDatabase = $('#selectDatabases :selected').text();
            if (parentItemID) {
                app = this;
                jQuery.ajax({
                    type: "GET",
                    dataType: "json",
                    data: { parentItemID: parentItemID, templateID: templateID, database: selectedDatabase },
                    url: "/api/sitecore/DeleteMultipleItems/GetSubItems",
                    cache: false,
                    success: function (data) {
                        if (data.result == "Found") {
                            $('.noresultfound').hide();
                            $('.deleteTableHeader').show();
                            app.set("subitems", data.SubItems);
                            document.getElementById('totalResultFound').innerHTML = "Total Results Found: " + data.SubItems.length;
                            $('.postActions').show();
                            $('.JchkAll').show();
                            $(".JchkAll").prop('checked', false);
                            $('.btnDeleteSelectedItems').show();
                            $("#divDeleteMultipleSubItems").children().colResizable();
                        }
                        else {
                            app.set("subitems", '');
                            $('.deleteTableHeader').hide();
                            $('.postActions').hide();
                            $('.JchkAll').hide();
                            $('.btnDeleteSelectedItems').hide();
                            $('.noresultfound').show();
                            document.getElementById('totalResultFound').innerHTML = "";
                        }
                    },
                    error: function () {
                        console.log("There was an error in GetSubItems() function!");
                    }
                });
            }
        },
        deleteSelectedItems: function (app) {
            var selectedDatabase = $('#selectDatabases :selected').text();
            var selectedIds = [];
            $(".JchkGrid").each(function () {
                if ($(this).is(':checked')) {
                    selectedIds.push($(this).text());
                }
            });
            if (selectedIds != [] && selectedIds) {
                app = this;
                jQuery.ajax({
                    type: "POST",
                    contentType: 'application/json',
                    data: JSON.stringify({ selectedIds: selectedIds, database: selectedDatabase }),
                    url: "/api/sitecore/DeleteMultipleItems/DeleteSelectedItems",
                    success: function (data) {
                        if (data) {
                            $('#responseResult').html(data);
                            $('#responseResult').show();
                            app.GetSubItems(this);
                            $("#chkall").prop('checked', false);

                        }
                    },
                    error: function () {
                        $('#responseResult').hide();
                        console.log("There was an error in DeleteSubItems() function!");
                    }
                });
            }
        }
    });

    var view = Sitecore.Definitions.Views.ControlView.extend({
        initialize: function (options) {
            this._super();
        }
    });

    Sitecore.Factories.createComponent("DeleteMultipleSubItems", model, view, ".sc-DeleteMultipleSubItems");
});

function filterToggle(element) {
    if (element.checked) {
        $(element).prop('checked', true);
    }
    else {
        $(element).prop('checked', false);
    }
}
function Selectall(currentJchkAll) {
    if ($(currentJchkAll).is(':checked')) {
        $('.JchkAll').prop('checked', true);
        $('.JchkGrid').prop('checked', true);
    }
    else {
        $('.JchkGrid').prop('checked', false);
        $('.JchkAll').prop('checked', false);
    }
}

$(".deleteTableHeader").colResizable({ liveDrag: true });
