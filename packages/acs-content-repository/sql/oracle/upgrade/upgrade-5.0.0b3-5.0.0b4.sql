-- there was an infinite loop in content_item.get_parent_folder if called with 
-- a child content_item rather than a content item which was directly below a 
-- folder.

@@ ../content-item.sql