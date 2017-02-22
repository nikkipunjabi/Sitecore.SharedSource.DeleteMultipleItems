<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Import Namespace="Sitecore.Configuration" %>
<%@ Import Namespace="Sitecore.Data.Fields" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Diagnostics" %>
<%@ Import Namespace="Sitecore.SecurityModel" %>
<%@ Import Namespace="Sitecore.sitecore.admin" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>

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

    <script language="CS" runat="server"> 

        public class SitecoreItems
        {
        public string ItemName { get; set; }
        public string ItemPath { get; set; }
        public string ItemDatabase { get; set; }
        public string ItemID { get; set; }
        }

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            if (Sitecore.Context.User.IsAdministrator == false)
            {
                Response.Redirect("login.aspx?returnUrl=bulkdelete.aspx");
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            chkall.Attributes.Add("onchange", "javascript: Selectall();");
        }

        protected void btnDelete_Click(object sender, EventArgs e)
        {


        }

        protected void btnShowAllChild_Click(object sender, EventArgs e)
        {
            litTotalResults.Visible = false;
            chkall.Visible = false;
            gridSitecoreItems.DataSource = "";
            gridSitecoreItems.DataBind();
            if (!string.IsNullOrWhiteSpace(txtParentItemId.Text) && Sitecore.Data.ID.IsID(txtParentItemId.Text))
            {
                var templateId = string.Empty;
                if (!string.IsNullOrWhiteSpace(txtTemplateId.Text) && Sitecore.Data.ID.IsID(txtTemplateId.Text))
                {
                    templateId = txtTemplateId.Text;
                    NoResultFound.Text = "Invalid Template ID";
                    NoResultFound.Visible = true;
                }
                var parentItem = Factory.GetDatabase("master").GetItem(txtParentItemId.Text);
                if (parentItem != null)
                {
                    List<SitecoreItems> sitecoreItems = new List<SitecoreItems>();
                    NoResultFound.Visible = false;
                    StringBuilder startItemPath = new StringBuilder(@"/");
                    startItemPath.Append(string.Join("/", parentItem.Paths.FullPath.Split(new char[] { '/' },
                    StringSplitOptions.RemoveEmptyEntries).Select(x => string.Format("#{0}#", x))));

                    List<Item> allChildItems = null;

                    if (string.IsNullOrWhiteSpace(templateId))
                    {
                        allChildItems = Factory.GetDatabase("master").SelectItems("fast:" + startItemPath + "/*").ToList();
                    }
                    else
                    {
                        allChildItems = Factory.GetDatabase("master").SelectItems("fast:" + startItemPath + "/*[@@templateid = '" + templateId + "']").ToList();
                    }

                    if (allChildItems != null && allChildItems.Any())
                    {
                        foreach (var item in allChildItems)
                        {
                            SitecoreItems sitecoreItem = new SitecoreItems();
                            sitecoreItem.ItemDatabase = item.Database.Name;
                            sitecoreItem.ItemID = item.ID.ToString();
                            sitecoreItem.ItemName = item.Name.ToString();
                            sitecoreItem.ItemPath = item.Paths.FullPath;
                            sitecoreItems.Add(sitecoreItem);
                        }
                        litTotalResults.Text = "Total Items Found: " + sitecoreItems.Count;
                        litTotalResults.Visible = true;
                        gridSitecoreItems.DataSource = sitecoreItems;
                        gridSitecoreItems.DataBind();
                        chkall.Visible = btnDeleteAllChild.Visible = true;
                    }
                    else
                    {
                        chkall.Visible = btnDeleteAllChild.Visible = false;
                        NoResultFound.Text = "No Result Found!";
                        NoResultFound.Visible = true;
                    }

                }
                else
                {
                    NoResultFound.Text = "No Result Found!";
                    btnDeleteAllChild.Visible = false;
                    NoResultFound.Visible = true;
                    chkall.Visible = false;
                }
                //https://www.asp.net/web-forms/overview/data-access/enhancing-the-gridview/adding-a-gridview-column-of-checkboxes-cs
            }
            else
            {
                NoResultFound.Text = "Invalid ID";
                btnDeleteAllChild.Visible = false;
                NoResultFound.Visible = true;
                chkall.Visible = false;
            }
        }

        protected void btnDeleteAllChild_Click(object sender, EventArgs e)
        {
            bool atLeastOneRowDeleted = false;
            // Iterate through the Products.Rows property
            List<Item> deleteChildItems = new List<Item>();
            foreach (GridViewRow row in gridSitecoreItems.Rows)
            {
                // Access the CheckBox
                CheckBox cb = (CheckBox)row.FindControl("chkDeleteItem");
                if (cb != null && cb.Checked)
                {
                    // Delete row! (Well, not really...)
                    atLeastOneRowDeleted = true;
                    // First, get the ProductID for the selected row
                    var itemID = row.Cells[2].Text;

                    var deleteItem = Factory.GetDatabase("master").GetItem(itemID);
                    if (deleteItem != null && deleteItem.HasChildren)
                    {
                        foreach (var child in deleteItem.Children.ToList())
                        {
                            deleteChildItems.Add(child);
                        }
                    }
                    if (deleteItem != null)
                    {
                        deleteChildItems.Add(deleteItem);
                    }
                }
            }

            if (deleteChildItems != null && deleteChildItems.Any())
            {
                try
                {
                    using (new SecurityDisabler())
                    {
                        foreach (var item in deleteChildItems)
                        {
                            var itemID = item.ID;
                            var itemName = item.Name.ToString();
                            var itemPath = item.Paths.FullPath;
                            RemoveReferenceLinks(item);
                            DeleteItem(item);

                            // "Delete" the row
                            DeleteResults.Text += string.Format(
                                "Deleted Item -- Name: {0} Path: {1} Id: {2}<br />", itemName, itemPath, itemID);
                        }
                    }
                }
                catch (Exception ex)
                {
                    Log.Error("Error in DeleteAllChild", ex, this);
                }

                btnShowAllChild_Click(sender, e);
            }

            // Show the Label if at least one row was deleted...
            DeleteResults.Visible = atLeastOneRowDeleted;
        }

        private static void DeleteItem(Item item)
        {
            Assert.ArgumentNotNull(item, "item");
            if (Settings.RecycleBinActive)
            {
                item.Recycle();
            }
            else
            {
                item.Delete();
            }
        }

        private string RemoveReferenceLinks(Item item)
        {
            var links = Sitecore.Globals.LinkDatabase.GetItemReferrers(item, true);

            if (links.Length == 0)
            {
                return "No referrence found";
            }

            foreach (var link in links)
            {
                var sourceItem = link.GetSourceItem();
                foreach (var item1 in sourceItem.Versions.GetVersions(true))
                {

                    var field = item1.Fields[link.SourceFieldID];
                    var field2 = FieldTypeManager.GetField(field);

                    if (field2 == null) return string.Empty;

                    using (new SecurityDisabler())
                    {
                        item1.Editing.BeginEdit();
                        field2.RemoveLink(link);
                        item1.Editing.EndEdit();
                    }

                }
            }

            return "All reference removed";
        }
    </script>
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
