-- 
-- 
-- 
-- @author Victor Guerra (guerra@galileo.edu)
-- @creation-date 2006-10-02
-- @arch-tag: c6a0a70c-5506-45e4-ba11-8e145f695c57
-- @cvs-id $Id$
--

select define_function_args('content_extlink__copy','extlink_id,target_folder_id,creation_user,creation_ip,name');
create or replace function content_extlink__copy (
	integer,
	integer,
	integer,
	varchar,
	varchar)
returns integer as '
declare
  copy__extlink_id             alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null
  copy__name                   alias for $5;
  v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_url                        cr_extlinks.url%TYPE;
  v_description                cr_extlinks.description%TYPE;
  v_label                      cr_extlinks.label%TYPE;
  v_extlink_id                 cr_extlinks.extlink_id%TYPE;
begin

  if content_folder__is_folder(copy__target_folder_id) = ''t'' then
    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy__extlink_id;

    -- can''t copy to the same folder

    select
      i.name, e.url, e.description, e.label
    into
      v_name, v_url, v_description, v_label
    from
      cr_extlinks e, cr_items i
    where
      e.extlink_id = i.item_id
    and
      e.extlink_id = copy__extlink_id;
	
	-- copy to a different folder, or same folder if name
	-- is different
    if copy__target_folder_id != v_current_folder_id  or ( v_name <> copy__name and copy__name is not null ) then

      if content_folder__is_registered(copy__target_folder_id,
        ''content_extlink'',''f'') = ''t'' then

        v_extlink_id := content_extlink__new(
            coalesce (copy__name, v_name),
            v_url,
            v_label,
            v_description,
            copy__target_folder_id,
            null,
            current_timestamp,
	    copy__creation_user,
	    copy__creation_ip,
            null
        );

      end if;
    end if;
  end if;

  return 0; 
end;' language 'plpgsql' stable;

