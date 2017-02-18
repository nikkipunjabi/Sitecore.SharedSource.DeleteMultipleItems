# Sitecore - Delete Multiple Items

Delete Multiple Items - A module for Content Authors to Delete Multiple Items.

  - Delete Multiple Items
  - Sitecore 7.0 Sheer UI - ASPX Application
  - Sitecore 8.2 Speak UI 

# About

  -  A Module for deleting Multiple Sitecore Items. This application was built first as an ASPX page (You can access it with /sitecore/admin/DeleteMultipleItems/DeleteMultipleItems.aspx), then provided an option in Sitecore Start Menu which can be used as an application as shown in screenshot. After that I learnt and explored Speak application via Knockout JS and then built a new application based on SPEAK UI which can run on Sitecore 8.0. Download the package based on the Sitecore version in which you are going to install.

Delete Multiple Items-0.1 (This is for all Sitecore versions):
  - Sitecore Core DB Items: 
    - /sitecore/content/Applications/Delete Multiple Items
    - /sitecore/content/Documents and settings/All users/Start menu/Left/Delete Multiple Items
  - Files:
    - Sitecore.SharedSource.DeleteMultipleItems.dll
    - /sitecore/admin/DeleteMultipleItems/DeleteMultipleItems.aspx

Delete Multiple Items-0.2 (This is for Sitecore 8.2):
  - Sitecore Core DB Items: 
    - /sitecore/client/Your Apps/Delete Multiple Items/Delete Multiple Items
    - /sitecore/content/Documents and settings/All users/Start menu/Left/Delete Multiple Items
  - Files:
    - Sitecore.SharedSource.DeleteMultipleItems.dll
    - /sitecore/shell/client/YourApps/DeleteMultipleSubItems

In this module you need to provide the Parent Item ID. It will fetch all the first level sub-items via Fast Query. You then can select the checkbox for the items which you want to delete and click Delete Selected Items button. It will delete the selected items, it's sub-items and also remove the links.

### Output
![Output](http://www.nikkipunjabi.com/Sitecore/DeleteMultipleItems/Screenshots/1.png "Output")
![Output](http://www.nikkipunjabi.com/Sitecore/DeleteMultipleItems/Screenshots/2.png "Output")
![Output](http://www.nikkipunjabi.com/Sitecore/DeleteMultipleItems/Screenshots/3.png "Output")
![Output](http://www.nikkipunjabi.com/Sitecore/DeleteMultipleItems/Screenshots/4.png "Output")

Thanks to [Vikram](https://cmsview.wordpress.com/tag/sitecore-speak-for-beginners/) for blogging the very good series of articles for SPEAK application. Thsi helped in gaining basic knowledge about Sitecore Speak application.

Thanks for reading this post and let me know if you face any issues.
You can anytime download the repository and update the module or let me know if you want any updates/changes.

Happy Sitecoring! :)

