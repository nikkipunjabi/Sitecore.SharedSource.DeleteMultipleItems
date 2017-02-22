using Sitecore.Configuration;
using Sitecore.Data.Fields;
using Sitecore.Data.Items;
using Sitecore.Diagnostics;
using Sitecore.SecurityModel;
using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Mvc;

namespace Sitecore.SharedSource.DeleteMultipleItems.Controllers
{
    public class DeleteMultipleItemsController : Controller
    {
        /// <summary>
        /// Wrapper class for Sitecore Sub-Items object
        /// </summary>
        public class SCSubItems
        {
            public string ItemName { get; set; }
            public string ItemID { get; set; }
            public string Database { get; set; }
            public string ItemPath { get; set; }

            public SCSubItems(Item item)
            {
                ItemName = item.Name;
                ItemID = item.ID.ToString();
                Database = item.Database.Name;
                ItemPath = item.Paths.FullPath;
            }
        }

        public class Result
        {
            public string result { get; set; }
            public List<SCSubItems> SubItems { get; set; }
        }

        public JsonResult GetDatabase()
        {
            dynamic obj = new ExpandoObject();

            if (Sitecore.Context.User != null && Sitecore.Context.User.IsAdministrator)
            {
                obj.isAdmin = true;
                try
                {
                    //obj.contentDatabase = Sitecore.Context.ContentDatabase.Name;
                    if (Sitecore.Context.ContentDatabase != null)
                    {
                        obj.database = Sitecore.Context.ContentDatabase.Name;
                    }
                    else
                    {
                        obj.database = Factory.GetDatabase("master").Name;
                    }
                }
                catch (Exception ex)
                {
                    Log.Error("Error in Sitecore.SharedSource.DeleteMultipleSubItems.GetDatabase", ex, this);
                }
            }
            else
            {
                obj.isAdmin = false;
            }
            return Json(obj, JsonRequestBehavior.AllowGet);

        }

        public ActionResult GetSubItems(string parentItemID, string templateID, string database)
        {

            var result = new Result();

            if (Sitecore.Context.User != null && Sitecore.Context.User.IsAdministrator)
            {

                if (!string.IsNullOrWhiteSpace(parentItemID) && !string.IsNullOrWhiteSpace(database) && Sitecore.Data.ID.IsID(parentItemID))
                {
                    try
                    {
                        var templateId = string.Empty;
                        if (!string.IsNullOrWhiteSpace(templateID) && Sitecore.Data.ID.IsID(templateID))
                        {
                            templateId = templateID;
                        }
                        var parentItem = Factory.GetDatabase(database).GetItem(parentItemID);
                        if (parentItem != null)
                        {
                            StringBuilder startItemPath = new StringBuilder(@"/");
                            startItemPath.Append(string.Join("/", parentItem.Paths.FullPath.Split(new char[] { '/' },
                            StringSplitOptions.RemoveEmptyEntries).Select(x => string.Format("#{0}#", x))));

                            List<Item> allChildItems = null;

                            if (string.IsNullOrWhiteSpace(templateId))
                            {
                                allChildItems = Factory.GetDatabase(database).SelectItems("fast:" + startItemPath + "/*").ToList();
                            }
                            else
                            {
                                allChildItems = Factory.GetDatabase(database).SelectItems("fast:" + startItemPath + "/*[@@templateid = '" + templateId + "']").ToList();
                            }

                            if (allChildItems != null && allChildItems.Any())
                            {
                                result.SubItems = allChildItems.Select(x => new SCSubItems(x)).ToList();
                                result.result = "Found";
                                return Json(result, JsonRequestBehavior.AllowGet);
                            }
                            else
                            {
                                //chkall.Visible = btnDeleteAllChild.Visible = false;
                                //NoResultFound.Visible = true;
                            }
                        }
                        else
                        {
                            //btnDeleteAllChild.Visible = false;
                            //NoResultFound.Visible = true;
                            //chkall.Visible = false;
                        }
                        //https://www.asp.net/web-forms/overview/data-access/enhancing-the-gridview/adding-a-gridview-column-of-checkboxes-cs
                    }
                    catch (Exception ex)
                    {
                        Log.Error("Error in Sitecore.SharedSource.GetSubItems", ex, this);
                    }
                }
            }

            return Json("", JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult DeleteSelectedItems(string[] selectedIds, string database)
        {
            var responseString = string.Empty;
            if (Sitecore.Context.User != null && Sitecore.Context.User.IsAdministrator)
            {
                if (!(string.IsNullOrWhiteSpace(database)) && selectedIds != null && selectedIds.Any())
                {
                    // Iterate through the Products.Rows property
                    List<Item> deleteChildItems = new List<Item>();

                    foreach (var id in selectedIds)
                    {
                        if (Sitecore.Data.ID.IsID(id))
                        {
                            var deleteItem = Factory.GetDatabase(database).GetItem(id);
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
                                    var itemName = item.Name;
                                    var itemPath = item.Paths.FullPath;
                                    RemoveReferenceLinks(item);
                                    DeleteItem(item);

                                    // "Delete" the row
                                    responseString += string.Format(
                                        "Deleted Item Id: {0} Item Name: {1} Item Path: {2} <br />", itemID, itemName, itemPath);
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            Log.Error("Error in DeleteAllChild", ex, this);
                            responseString += string.Format("There was an error: " + ex);
                        }
                    }
                }
            }
            return Json(responseString, JsonRequestBehavior.AllowGet);
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