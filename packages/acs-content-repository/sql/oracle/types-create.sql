-- Object type declarations to support content repository of the
-- ArsDigita Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- Define content items.  Also the supertype for folders, symlinks and extlinks.

declare
 attr_id	acs_attributes.attribute_id%TYPE;
begin

 acs_object_type.create_type (
   supertype     => 'acs_object',
   object_type   => 'content_item',
   pretty_name   => 'Content Item',
   pretty_plural => 'Content Items',
   table_name    => 'cr_items',
   id_column     => 'item_id',
   name_method   => 'content_item.get_title'
 );

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_item',
   attribute_name => 'name',
   datatype       => 'keyword',
   pretty_name    => 'Name',
   pretty_plural  => 'Names'
 ); 

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_item',
   attribute_name => 'locale',
   datatype       => 'keyword',
   pretty_name    => 'Locale',
   pretty_plural  => 'Locales'
 );

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_item',
   attribute_name => 'live_revision',
   datatype       => 'integer',
   pretty_name    => 'Live Revision',
   pretty_plural  => 'Live Revisions'
 );

end;
/
show errors

-- Define content folders.  A folder is equivalent to a directory in
-- the file system.  It is used for grouping content items that have
-- public URL's.

declare
 attr_id	acs_attributes.attribute_id%TYPE;
begin

 acs_object_type.create_type (
   supertype     => 'content_item',
   object_type   => 'content_folder',
   pretty_name   => 'Content Folder',
   pretty_plural => 'Content Folders',
   table_name    => 'cr_folders',
   id_column     => 'folder_id',
   name_method   => 'content_folder.get_label'
 );

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_folder',
   attribute_name => 'label',
   datatype       => 'string',
   pretty_name    => 'Label',
   pretty_plural  => 'Labels'
 ); 

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_folder',
   attribute_name => 'description',
   datatype       => 'string',
   pretty_name    => 'Description',
   pretty_plural  => 'Descriptions'
 );

end;
/
show errors
  

-- Define content keywords

declare
 attr_id	acs_attributes.attribute_id%TYPE;
begin

 acs_object_type.create_type (
   supertype     => 'acs_object',
   object_type   => 'content_keyword',
   pretty_name   => 'Content Keyword',
   pretty_plural => 'Content Keywords',
   table_name    => 'cr_keywords',
   id_column     => 'keyword_id',
   name_method   => 'acs_object.default_name'
 );

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_keyword',
   attribute_name => 'heading',
   datatype       => 'string',
   pretty_name    => 'Heading',
   pretty_plural  => 'Headings'
 ); 

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_keyword',
   attribute_name => 'description',
   datatype       => 'string',
   pretty_name    => 'Description',
   pretty_plural  => 'Descriptions'
 );

end;
/
show errors

-- Symlinks are represented by a subclass of content_item (content_link)

-- Each symlink thus has a row in the acs_objects table.  Each symlink 
-- also has a row in the cr_items table.  The name column for the symlink 
-- is the name that appears in the path to the symlink.

declare
  attr_id integer;
begin

 acs_object_type.create_type (
   supertype     => 'content_item',
   object_type   => 'content_symlink',
   pretty_name   => 'Content Symlink',
   pretty_plural => 'Content Symlinks',
   table_name    => 'cr_symlinks',
   id_column     => 'symlink_id',
   name_method   => 'acs_object.default_name'
 );

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_symlink',
   attribute_name => 'target_id',
   datatype       => 'integer',
   pretty_name    => 'Target ID',
   pretty_plural  => 'Target IDs'
 ); 

end;
/
show errors

-- Extlinks are links to external content (offsite URL's)

declare
  attr_id integer;
begin

 acs_object_type.create_type (
   supertype     => 'content_item',
   object_type   => 'content_extlink',
   pretty_name   => 'External Link',
   pretty_plural => 'External Links',
   table_name    => 'cr_extlinks',
   id_column     => 'extlink_id',
   name_method   => 'acs_object.default_name'
 );

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_extlink',
   attribute_name => 'url',
   datatype       => 'text',
   pretty_name    => 'URL',
   pretty_plural  => 'URLs'
 ); 

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_extlink',
   attribute_name => 'label',
   datatype       => 'text',
   pretty_name    => 'Label',
   pretty_plural  => 'Labels'
 ); 

 attr_id := acs_attribute.create_attribute (
   object_type    => 'content_extlink',
   attribute_name => 'description',
   datatype       => 'text',
   pretty_name    => 'Description',
   pretty_plural  => 'Descriptions'
 ); 

end;
/
show errors

-- Define content templates.  

begin

 acs_object_type.create_type (
   supertype => 'content_item',
   object_type => 'content_template',
   pretty_name => 'Content Template',
   pretty_plural => 'Content Templates',
   table_name => 'cr_templates',
   id_column => 'template_id',
   name_method => 'acs_object.default_name'
 );

end;
/
show errors

-- Define content revisions, children of content items

declare
 attr_id	acs_attributes.attribute_id%TYPE;
begin

 content_type.create_type (
   supertype     => 'acs_object',
   content_type  => 'content_revision',
   pretty_name   => 'Basic Item',
   pretty_plural => 'Basic Items',
   table_name    => 'cr_revisions',
   id_column     => 'revision_id',
   name_method   => 'content_revision.revision_name'
 );

 attr_id := content_type.create_attribute (
   content_type   => 'content_revision',
   attribute_name => 'title',
   datatype       => 'text',
   pretty_name    => 'Title',
   pretty_plural  => 'Titles',
   sort_order     => 1
 );

 attr_id := content_type.create_attribute (
   content_type    => 'content_revision',
   attribute_name => 'description',
   datatype       => 'text',
   pretty_name    => 'Description',
   pretty_plural  => 'Descriptions',
   sort_order     => 2
 );

 attr_id := content_type.create_attribute (
   content_type   => 'content_revision',
   attribute_name => 'publish_date',
   datatype       => 'date',
   pretty_name    => 'Publish Date',
   pretty_plural  => 'Publish Dates',
   sort_order     => 3
 );

 attr_id := content_type.create_attribute (
   content_type   => 'content_revision',
   attribute_name => 'mime_type',
   datatype       => 'text',
   pretty_name    => 'Mime Type',
   pretty_plural  => 'Mime Types',
   sort_order     => 4
 );

 attr_id := content_type.create_attribute (
   content_type   => 'content_revision',
   attribute_name => 'nls_language',
   datatype => 'text',
   pretty_name => 'Language',
   pretty_plural => 'Language'
 );

 attr_id := content_type.create_attribute (
   content_type   => 'content_revision',
   attribute_name => 'item_id',
   datatype => 'integer',
   pretty_name => 'Item id',
   pretty_plural => 'Item ids'
 );

 attr_id := content_type.create_attribute (
   content_type   => 'content_revision',
   attribute_name => 'content',
   datatype => 'text',
   pretty_name => 'content',
   pretty_plural => 'content'
 );

end;
/
show errors

-- Declare standard relationships with children and other items

declare
 attr_id	acs_attributes.attribute_id%TYPE;
begin

 acs_object_type.create_type (
   supertype => 'acs_object',
   object_type => 'cr_item_child_rel',
   pretty_name => 'Child Item',
   pretty_plural => 'Child Items',
   table_name => 'cr_child_rels',
   id_column => 'rel_id',
   name_method => 'acs_object.default_name'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_item_child_rel',
   attribute_name => 'parent_id',
   datatype => 'integer',
   pretty_name => 'Parent ID',
   pretty_plural => 'Parent IDs'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_item_child_rel',
   attribute_name => 'child_id',
   datatype => 'integer',
   pretty_name => 'Child ID',
   pretty_plural => 'Child IDs'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_item_child_rel',
   attribute_name => 'relation_tag',
   datatype => 'text',
   pretty_name => 'Relationship Tag',
   pretty_plural => 'Relationship Tags'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_item_child_rel',
   attribute_name => 'order_n',
   datatype => 'integer',
   pretty_name => 'Sort Order',
   pretty_plural => 'Sort Orders'
 );

 acs_object_type.create_type (
   supertype => 'acs_object',
   object_type => 'cr_item_rel',
   pretty_name => 'Item Relationship',
   pretty_plural => 'Item Relationships',
   table_name => 'cr_item_rels',
   id_column => 'rel_id',
   name_method => 'acs_object.default_name'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_item_rel',
   attribute_name => 'item_id',
   datatype => 'integer',
   pretty_name => 'Item ID',
   pretty_plural => 'Item IDs'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_item_rel',
   attribute_name => 'related_object_id',
   datatype => 'integer',
   pretty_name => 'Related Object ID',
   pretty_plural => 'Related Object IDs'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_item_rel',
   attribute_name => 'relation_tag',
   datatype => 'text',
   pretty_name => 'Relationship Tag',
   pretty_plural => 'Relationship Tags'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_item_rel',
   attribute_name => 'order_n',
   datatype => 'integer',
   pretty_name => 'Sort Order',
   pretty_plural => 'Sort Orders'
 );

end;
/
show errors

-- Refresh the attribute views

prompt *** Refreshing content type attribute views...

begin

  for type_rec in (select object_type from acs_object_types 
    connect by supertype = prior object_type 
    start with object_type = 'content_revision') loop
    content_type.refresh_view(type_rec.object_type);
  end loop;

end;
/
