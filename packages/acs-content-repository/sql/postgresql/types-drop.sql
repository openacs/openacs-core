-- Drop script for clearing content-repositry object type declarations

-- Copyright (C) 20000 ArsDigita Corporation

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- just working backwards from types declared in types-create.sql


-- removing the standard relationship types
begin;

select acs_attribute__drop_attribute (
  'cr_item_rel',
  'order_n');


select acs_attribute__drop_attribute (
  'cr_item_rel',
  'relation_tag');


select acs_attribute__drop_attribute (
  'cr_item_rl',
  'related_object_id');

select acs_attribute__drop_attribute (
  'cr_item_rl',
  'item_id');

select acs_object_type__drop_type (
  'cr_item_rel', 'f');


-- cr_item_child_rel type
select acs_attribute__drop_attribute (
  'cr_item_child_rel',
  'order_n');

select acs_attribute__drop_attribute (
  'cr_item_child_rel',
  'relation_tag');

select acs_attribute__drop_attribute (
  'cr_item_child_rel',
  'child_id');

select acs_attribute__drop_attribute (
  'cr_item_child_rel',
  'parent_id');

select acs_object_type__drop_type (
  'cr_item_child_rel', 'f');

end;


-- drop content revisions, 
begin;

  select content_type__drop_type('content_revision',f','f');

end;


--dropping content templates
begin;

select acs_object_type__drop_type(
  'content_template','f');

end;

-- extlinks
begin;

  select acs_attribute__drop_attribute (
    'content_extlink',
    'description');

  select acs_attribute__drop_attribute (
    'content_extlink',
    attribute_name	=> 'label');

  select acs_attribute__drop_attribute (
    'content_extlink',
    attribute_name	=> 'url');

  select acs_object_type__drop_type(
    'content_extlink','f');

end;

-- symlinks
begin;

  select acs_attribute__drop_attribute (
    'content_symlink',
    'target_id');

  select acs_object_type__drop_type (
    'content_symlink');

end;

--content keywords
begin;

  select acs_attribute__drop_attribute (
    'content_keyword',
    attribute_name	=> 'description');

  select acs_attribute__drop_attribute (
    'content_keyword',
    attribute_name	=> 'heading');

  select acs_object_type__drop_type (
    'content_keyword','f');

end;

begin;

  select acs_attribute__drop_attribute (
    'content_folder',
    'description');

  select acs_attribute__drop_attribute (
    'content_folder',
    'label');

  select acs_object_type__drop_type (
    'content_folder','f');

end;

begin;

select acs_attribute__drop_attribute (
  'content_item',
  'live_revision');

select acs_attribute__drop_attribute (
  'content_item',
  'locale');

select acs_attribute__drop_attribute (
  'content_item',
  'name');

select acs_object_type__drop_type ( 
  'content_item','f');

end;



