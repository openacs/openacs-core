-- Object type declarations to support content repository of the
-- ArsDigita Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- Define content items.  Also the supertype for folders, symlinks and extlinks.

begin;

 select acs_object_type__create_type (
   'content_item',
   'Content Item',
   'Content Items',
   'acs_object',
   'cr_items',
   'item_id',
   null,
   'f',
   null,
   'content_item.get_title'
 );

 select acs_attribute__create_attribute (
   'content_item',
   'name',
   'keyword',
   'Name',
   'Names',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 ); 

 select acs_attribute__create_attribute (
   'content_item',
   'locale',
   'keyword',
   'Locale',
   'Locales',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

 select acs_attribute__create_attribute (
   'content_item',
   'live_revision',
   'integer',
   'Live Revision',
   'Live Revisions',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

end;

-- Define content folders.  A folder is equivalent to a directory in
-- the file system.  It is used for grouping content items that have
-- public URL's.

begin;

 select acs_object_type__create_type (
   'content_folder',
   'Content Folder',
   'Content Folders',
   'content_item',
   'cr_folders',
   'folder_id',
   null,
   'f',
   null,
   'content_folder.get_label'
 );

 select acs_attribute__create_attribute (
   'content_folder',
   'label',
   'string',
   'Label',
   'Labels',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 ); 

 select acs_attribute__create_attribute (
   'content_folder',
   'description',
   'string',
   'Description',
   'Descriptions',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

end;
  

-- Define content keywords

begin;

 select acs_object_type__create_type (
   'content_keyword',
   'Content Keyword',
   'Content Keywords',
   'acs_object',
   'cr_keywords',
   'keyword_id',
   null,
   'f',
   null,
   'acs_object.default_name'
 );

 select acs_attribute__create_attribute (
   'content_keyword',
   'heading',
   'string',
   'Heading',
   'Headings',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 ); 

 select acs_attribute__create_attribute (
   'content_keyword',
   'description',
   'string',
   'Description',
   'Descriptions',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

end;

-- Symlinks are represented by a subclass of content_item (content_link)

-- Each symlink thus has a row in the acs_objects table.  Each symlink 
-- also has a row in the cr_items table.  The name column for the symlink 
-- is the name that appears in the path to the symlink.

begin;

 select acs_object_type__create_type (
   'content_symlink',
   'Content Symlink',
   'Content Symlinks',
   'content_item',
   'cr_symlinks',
   'symlink_id',
   null,
   'f',
   null,
   'acs_object.default_name'
 );

 select acs_attribute__create_attribute (
   'content_symlink',
   'target_id',
   'integer',
   'Target ID',
   'Target IDs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 ); 

end;

-- Extlinks are links to external content (offsite URL's)

begin;

 select acs_object_type__create_type (
   'content_extlink',
   'External Link',
   'External Links',
   'content_item',
   'cr_extlinks',
   'extlink_id',
   null,
   'f',
   null,
   'acs_object.default_name'
 );

 select acs_attribute__create_attribute (
   'content_extlink',
   'url',
   'text',
   'URL',
   'URLs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 ); 

 select acs_attribute__create_attribute (
   'content_extlink',
   'label',
   'text',
   'Label',
   'Labels',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 ); 

 select acs_attribute__create_attribute (
   'content_extlink',
   'description',
   'text',
   'Description',
   'Descriptions',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 ); 

end;

-- Define content templates.  

begin;

 select acs_object_type__create_type (
   'content_template',
   'Content Template',
   'Content Templates',
   'content_item',
   'cr_templates',
   'template_id',
   null,
   'f',
   null,
   'acs_object.default_name'
 );

end;

-- Define content revisions, children of content items

begin;

 select content_type__create_type (
   'content_revision',
   'acs_object',
   'Basic Item',
   'Basic Items',
   'cr_revisions',
   'revision_id',
   'content_revision.revision_name'
 );

 select content_type__create_attribute (
   'content_revision',
   'title',
   'text',
   'Title',
   'Titles',
   1,
   null,
   'text'
 );

 select content_type__create_attribute (
    'content_revision',
   'description',
   'text',
   'Description',
   'Descriptions',
   2,
   null,
   'text'
 );

 select content_type__create_attribute (
   'content_revision',
   'publish_date',
   'date',
   'Publish Date',
   'Publish Dates',
   3,
   null,
   'text'
 );

 select content_type__create_attribute (
   'content_revision',
   'mime_type',
   'text',
   'Mime Type',
   'Mime Types',
   4,
   null,
   'text'
 );

 select content_type__create_attribute (
   'content_revision',
   'nls_language',
   'text',
   'Language',
   'Language',
   null,
   null,
   'text'
 );

 select content_type__create_attribute (
   'content_revision',
   'item_id',
   'integer',
   'Item id',
   'Item ids',
   null,
   null,
   'integer'
 );

 select content_type__create_attribute (
   'content_revision',
   'content',
   'text',
   'Content',
   'Content',
   null,
   null,
   'text'
 );

end;

-- Declare standard relationships with children and other items

begin;

 select acs_object_type__create_type (
   'cr_item_child_rel',
   'Child Item',
   'Child Items',
   'acs_object',
   'cr_child_rels',
   'rel_id',
   null,
   'f',
   null,
   'acs_object.default_name'
 );

 select acs_attribute__create_attribute (
   'cr_item_child_rel',
   'parent_id',
   'integer',
   'Parent ID',
   'Parent IDs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

 select acs_attribute__create_attribute (
   'cr_item_child_rel',
   'child_id',
   'integer',
   'Child ID',
   'Child IDs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

 select acs_attribute__create_attribute (
   'cr_item_child_rel',
   'relation_tag',
   'text',
   'Relationship Tag',
   'Relationship Tags',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

 select acs_attribute__create_attribute (
   'cr_item_child_rel',
   'order_n',
   'integer',
   'Sort Order',
   'Sort Orders',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

 select acs_object_type__create_type (
   'cr_item_rel',
   'Item Relationship',
   'Item Relationships',
   'acs_object',
   'cr_item_rels',
   'rel_id',
   null,
   'f',
   null,
   'acs_object.default_name'
 );

 select acs_attribute__create_attribute (
   'cr_item_rel',
   'item_id',
   'integer',
   'Item ID',
   'Item IDs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

 select acs_attribute__create_attribute (
   'cr_item_rel',
   'related_object_id',
   'integer',
   'Related Object ID',
   'Related Object IDs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

 select acs_attribute__create_attribute (
   'cr_item_rel',
   'relation_tag',
   'text',
   'Relationship Tag',
   'Relationship Tags',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

 select acs_attribute__create_attribute (
   'cr_item_rel',
   'order_n',
   'integer',
   'Sort Order',
   'Sort Orders',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
 );

end;

-- Refresh the attribute views

-- prompt *** Refreshing content type attribute views...

create function inline_0 () returns integer as '
declare
        type_rec   record;       
begin

-- select object_type from acs_object_types 
--    connect by supertype = prior object_type 
--    start with object_type = ''content_revision'' 

  for type_rec in select o1.object_type
                  from acs_object_types o1, acs_object_types o2
                  where o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
                    and o2.object_type = ''content_revision''
                  
  LOOP
    PERFORM content_type__refresh_view(type_rec.object_type);
  end LOOP;

  return null;
end;' language 'plpgsql';

select inline_0();

drop function inline_0();
