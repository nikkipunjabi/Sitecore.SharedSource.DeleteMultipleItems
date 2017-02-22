using Sitecore.Configuration;
using Sitecore.Data.Fields;
using Sitecore.Data.Items;
using Sitecore.Diagnostics;
using Sitecore.SecurityModel;
using Sitecore.sitecore.admin;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sitecore.SharedSource.DeleteMultipleItems.sitecore.admin.DeleteMultipleItems
{
    public class SitecoreItems
    {
        public string ItemName { get; set; }
        public string ItemPath { get; set; }
        public string ItemDatabase { get; set; }
        public string ItemID { get; set; }
    }
    public partial class DeleteMultipleItems : AdminPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            chkall.Attributes.Add("onchange", "javascript: Selectall();");
        }

        protected override void OnInit(EventArgs e)
        {
            CheckSecurity(true); //Required!
            base.OnInit(e);
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
            var links = Globals.LinkDatabase.GetItemReferrers(item, true);

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
    }
}