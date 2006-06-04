-- update package content_template to add package_id parameter

create or replace package content_template
as

c_root_folder_id constant integer := -200;

function get_root_folder return cr_folders.folder_id%TYPE;

function new (
  --/** Creates a new content template which can be used to render content items.
  --    @author Karl Goldstein
  --    @param name          The name for the template, must be a valid UNIX-like filename.
  --                         If a template with this name already exists under the specified
  --                         parent item, an error is thrown
  --    @param text          The body of the .adp template itself, defaults to null
  --    @param parent_id     The parent of this item, defaults to null
  --    @param is_live       The should the revision be set live, defaults to 't'. Requires
  --                         that text is not null or there will be no revision to begin with                             
  --    @param template_id   The id of the new template. A new id will be allocated if this
  --                         parameter is null
  --    @param creation_date As in <tt>acs_object.new</tt>
  --    @param creation_ip   As in <tt>acs_object.new</tt>
  --    @param creation_user As in <tt>acs_object.new</tt>
  --    @return The id of the newly created template
  --    @see {acs_object.new}, {content_item.new}, {content_item.register_template},
  --         {content_type.register_template}
  --*/
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
) return cr_templates.template_id%TYPE;

procedure del (
  --/** Deletes the specified template, and unregisters the template from
  --    all content types and content items.
  --    Use with caution - this operation cannot be undone.
  --    @author Karl Goldstein
  --    @param template_id        The id of the template to delete
  --    @see {acs_object.delete}, {content_item.unregister_template}, 
  --         {content_type.unregister_template},
  --*/
  template_id	in cr_templates.template_id%TYPE
);

function is_template (
  --/** Determine if an item is a template.
  --    @author Karl Goldstein
  --    @param item_id  The item id        
  --    @return 't' if the item is a template, 'f' otherwise
  --    @see {content_template.new}
  --*/
  template_id	in cr_templates.template_id%TYPE
) return varchar2;

function get_path (
  --/** Retrieves the full path to the template, as described in content_item.get_path
  --    @author Karl Goldstein
  --    @param template_id        The id of the template for which the path is to 
  --                              be retrieved
  --    @param root_folder_id     Starts path resolution at this folder
  --    @return The path to the template, starting with the specified root folder
  --    @see {content_item.get_path}
  --*/
  template_id    in cr_templates.template_id%TYPE,
  root_folder_id in cr_folders.folder_id%TYPE default c_root_folder_id
) return varchar2;

end content_template;
/
show errors

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
