<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DeleteMultipleItems.aspx.cs" Inherits="Sitecore.SharedSource.DeleteMultipleItems.sitecore.admin.DeleteMultipleItems.DeleteMultipleItems" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" />
    <style>
        .txtBoxSize {
            width: 450px;
        }

        .marginFooter {
            margin-bottom: 15px;
            margin-top: 15px;
        }

        .center-block {
            margin-left: auto;
            margin-right: auto;
            display: block;
        }
    </style>
</head>
<body>
    <form runat="server">
        <div class="container text-center">
            <div class="row">

                <h2>Delete Multiple Items</h2>
            </div>
            <div class="form-group center-block">
                <div class="row">
                    <div class="col-md-3"></div>
                    <div class="col-md-6">
                        <asp:TextBox ID="txtParentItemId" placeholder="Parent Item ID*" CssClass="form-control" runat="server"></asp:TextBox>
                    </div>
                    <div class="col-md-3"></div>
                </div>
                <br />
                <div class="row">
                    <div class="col-md-3"></div>
                    <div class="col-md-6">
                        <asp:TextBox placeholder="Template ID" ID="txtTemplateId" CssClass="form-control" runat="server"></asp:TextBox>
                    </div>
                    <div class="col-md-3"></div>
                </div>
                <br />
                <div class="row">
                    <asp:Button ID="btnShowAllChild" CssClass="btn" OnClick="btnShowAllChild_Click" runat="server" Text="Show Sub-Items" />
                </div>
            </div>
            <br />

            <div class="row">
                <asp:Literal ID="NoResultFound" Text="No Result Found!" runat="server" Visible="false"></asp:Literal>
                <asp:Literal ID="litTotalResults" runat="server" Visible="false"></asp:Literal>
            </div>
            <asp:GridView ID="gridSitecoreItems" CssClass="container-fluid deleteTableHeader" runat="server" AutoGenerateColumns="false"
                Font-Size="13pt" BackColor="Khaki"
                AlternatingRowStyle-BackColor="Tan"
                HeaderStyle-BackColor="SlateGray"
                HeaderStyle-ForeColor="White"
                HeaderStyle-Font-Bold="True">
                <Columns>
                    <asp:BoundField DataField="ItemName" HeaderText="Name" />
                    <asp:BoundField DataField="ItemPath" HeaderText="Path" />
                    <asp:BoundField DataField="ItemID" HeaderText="Item ID" />
                    <asp:BoundField DataField="ItemDatabase" HeaderText="Database" />
                    <asp:TemplateField HeaderText="Delete">
                        <ItemTemplate>
                            <div class="chkBoxes">
                                <asp:CheckBox CssClass="JchkGrid" ID="chkDeleteItem" runat="server" />
                            </div>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                <SelectedRowStyle BackColor="LightCyan"
                    ForeColor="DarkBlue"
                    Font-Bold="true" />
            </asp:GridView>

            <div class="row marginFooter">
                <asp:CheckBox runat="server" ID="chkall" Visible="false" Text="Select/Deselect All" CssClass="JchkAll" />
                <asp:Button ID="btnDeleteAllChild" CssClass="btn btn-primary " OnClick="btnDeleteAllChild_Click" Visible="false" Text="Delete Selected Items" runat="server" />
            </div>
            <p>
                <asp:Label ID="DeleteResults" runat="server" EnableViewState="False"
                    Visible="False"></asp:Label>
            </p>
        </div>
    </form>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.1/jquery.min.js"></script>
    <script type="text/javascript">
        function Selectall() {
            if ($('#<%= chkall.ClientID  %>').is(':checked')) {
                $(".chkBoxes :input").each(function () {
                    $(this).prop('checked', true);
                });
            }
            else {
                $(".chkBoxes :input").each(function () {
                    $(this).prop('checked', false);
                });
            }
        }
    </script>
</body>
</html>
