-- Data model to support content repository of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create or replace package body content_template
as

function get_root_folder
return cr_folders.folder_id%TYPE
is
begin
  return c_root_folder_id;
end get_root_folder;

function new (
  name          in cr_items.name%TYPE,
  text          in varchar2 default null,
  parent_id     in cr_items.parent_id%TYPE default null,
  is_live 		in char default 't',
  template_id	in cr_templates.template_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  package_id    in acs_objects.package_id%TYPE default null 
) return cr_templates.template_id%TYPE
is

  v_template_id		cr_templates.template_id%TYPE;
  v_parent_id		cr_items.parent_id%TYPE;
  v_package_id		acs_objects.package_id%TYPE;

begin

  if parent_id is null then
    v_parent_id := c_root_folder_id;
  else
    v_parent_id := parent_id;
  end if;

  -- make sure we're allowed to create a template in this folder
  if content_folder.is_folder(parent_id) = 't' and
    content_folder.is_registered(parent_id,'content_template') = 'f' then

    raise_application_error(-20000, 
        'This folder does not allow templates to be created');

  else
    if package_id is null then
      v_package_id := acs_object.package_id(v_parent_id);
    else
      v_package_id := package_id;
    end if;

    v_template_id := content_item.new (
        item_id       => content_template.new.template_id,
        name          => content_template.new.name, 
        text          => content_template.new.text, 
        parent_id     => v_parent_id,
        package_id    => v_package_id,
        content_type  => 'content_template',
        is_live       => content_template.new.is_live, 
        creation_date => content_template.new.creation_date, 
        creation_user => content_template.new.creation_user, 
        creation_ip   => content_template.new.creation_ip
    );

    insert into cr_templates ( 
      template_id 
    ) values (
      v_template_id
    );

    return v_template_id;
  end if;
end new;                 

-- delete all template relations
procedure del (
  template_id	in cr_templates.template_id%TYPE
) is
begin

  delete from cr_type_template_map
    where template_id = content_template.del.template_id;

  delete from cr_item_template_map
    where template_id = content_template.del.template_id;
 
  delete from cr_templates
    where template_id = content_template.del.template_id;

  content_item.del(content_template.del.template_id);

end del;

function is_template (
  template_id	in cr_templates.template_id%TYPE
) return varchar2
is
  v_ret varchar2(1);
begin
  
  select 't' into v_ret from cr_templates
    where template_id = is_template.template_id;
  
  return v_ret; 

exception when no_data_found then
  return 'f';
end is_template;

function get_path (
  template_id    in cr_templates.template_id%TYPE,
  root_folder_id in cr_folders.folder_id%TYPE default c_root_folder_id
) return varchar2 is

begin

  return content_item.get_path(template_id, root_folder_id);

end get_path;

end content_template;
/
show errors
