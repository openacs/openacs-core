-- Drop script for clearing content-repositry object type declarations

-- Copyright (C) 20000 ArsDigita Corporation

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- just working backwards from types declared in types-create.sql


-- removing the standard relationship types
begin

acs_attribute.drop_attribute (
  object_type => 'cr_item_rel',
  attribute_name => 'order_n');


acs_attribute.drop_attribute (
  object_type => 'cr_item_rel',
  attribute_name => 'relation_tag');


acs_attribute.drop_attribute (
  object_type => 'cr_item_rl',
  attribute_name => 'related_object_id');

acs_attribute.drop_attribute (
  object_type => 'cr_item_rl',
  attribute_name => 'item_id');

acs_object_type.drop_type (
  object_type => 'cr_item_rel');


-- cr_item_child_rel type
acs_attribute.drop_attribute (
  object_type => 'cr_item_child_rel',
  attribute_name => 'order_n');

acs_attribute.drop_attribute (
  object_type => 'cr_item_child_rel',
  attribute_name => 'relation_tag');

acs_attribute.drop_attribute (
  object_type => 'cr_item_child_rel',
  attribute_name => 'child_id');

acs_attribute.drop_attribute (
  object_type => 'cr_item_child_rel',
  attribute_name => 'parent_id');

acs_object_type.drop_type (
  object_type => 'cr_item_child_rel');

end;
/
show errors


-- drop content revisions, 
begin

content_type.drop_type('content_revision');

end;
/
show errors


--dropping content templates
begin

acs_object_type.drop_type(
  object_type => 'content_template');

end;
/
show errors

-- extlinks
begin

  acs_attribute.drop_attribute (
    object_type   => 'content_extlink',
    attribute_name => 'description');

  acs_attribute.drop_attribute (
    object_type => 'content_extlink',
    attribute_name	=> 'label');

  acs_attribute.drop_attribute (
    object_type => 'content_extlink',
    attribute_name	=> 'url');

  acs_object_type.drop_type(
    object_type => 'content_extlink');

end;
/
show errors

-- symlinks
begin

  acs_attribute.drop_attribute (
    object_type => 'content_symlink',
    attribute_name => 'target_id');

  acs_object_type.drop_type (
    object_type => 'content_symlink');

end;
/
show errors

--content keywords
begin

  acs_attribute.drop_attribute (
    object_type => 'content_keyword',
    attribute_name	=> 'description');

  acs_attribute.drop_attribute (
    object_type => 'content_keyword',
    attribute_name	=> 'heading');

  acs_object_type.drop_type (
    object_type => 'content_keyword');

end;
/
show errors

begin

  acs_attribute.drop_attribute (
    object_type	   => 'content_folder',
    attribute_name => 'description');

  acs_attribute.drop_attribute (
    object_type => 'content_folder',
    attribute_name => 'label');

  acs_object_type.drop_type (
    object_type => 'content_folder');

end;
/
show errors

begin

acs_attribute.drop_attribute (
  object_type => 'content_item',
  attribute_name => 'live_revision');

acs_attribute.drop_attribute (
  object_type => 'content_item',
  attribute_name => 'locale');

acs_attribute.drop_attribute (
  object_type => 'content_item',
  attribute_name => 'name');

acs_object_type.drop_type ( 
  object_type => 'content_item');

end;
/
show errors



