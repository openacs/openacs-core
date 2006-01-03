-- Refresh the attribute triggers

begin

  for type_rec in (select object_type,table_name from acs_object_types
    connect by supertype = prior object_type 
    start with object_type = 'content_revision') loop
        if table_exists(type_rec.table_name) then
            content_type.refresh_view(type_rec.object_type);
            content_type.refresh_trigger(type_rec.object_type);
             content_type.refresh_view(type_rec.object_type);
        end if; 
  end loop;

end;
/
show errors;

-- recreate content keyword package for package_id

create or replace package content_keyword
as

function new (
  --/** Creates a new keyword (also known as "subject category").
  --    @author Karl Goldstein
  --    @param heading       The heading for the new keyword
  --    @param description   The description for the new keyword
  --    @param parent_id     The parent of this keyword, defaults to null.
  --    @param keyword_id    The id of the new keyword. A new id will be allocated if this
  --                         parameter is null
  --    @param object_type   The type for the new keyword, defaults to 'content_keyword'.
  --                         This parameter may be used by subclasses of 
  --                         <tt>content_keyword</tt> to initialize the superclass.
  --    @param creation_date As in <tt>acs_object.new</tt>
  --    @param creation_ip   As in <tt>acs_object.new</tt>
  --    @param creation_user As in <tt>acs_object.new</tt>
  --    @param package_id As in <tt>acs_object.new</tt>
  --    @return The id of the newly created keyword
  --    @see {acs_object.new}, {content_item.new}, {content_keyword.item_assign},
  --         {content_keyword.delete}
  --*/
  heading       in cr_keywords.heading%TYPE,
  description   in cr_keywords.description%TYPE default null,
  parent_id     in cr_keywords.parent_id%TYPE default null,
  keyword_id    in cr_keywords.keyword_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  object_type   in acs_object_types.object_type%TYPE default 'content_keyword',
  package_id    in acs_objects.package_id%TYPE
) return cr_keywords.keyword_id%TYPE;

procedure del (
  --/** Deletes the specified keyword, which must be a leaf. Unassigns the
  --    keyword from all content items.  Use with caution - this
  --    operation cannot be undone.
  --    @author Karl Goldstein
  --    @param keyword_id The id of the keyword to be deleted
  --    @see {acs_object.delete}, {content_keyword.item_unassign}
  --*/  
  keyword_id  in cr_keywords.keyword_id%TYPE
);

function get_heading (
  --/** Retrieves the heading of the content keyword
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id
  --    @return The heading for the specified keyword
  --    @see {content_keyword.set_heading}, {content_keyword.get_description}
  --*/
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2;

function get_description (
  --/** Retrieves the description of the content keyword
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id
  --    @return The description for the specified keyword
  --    @see {content_keyword.get_heading}, {content_keyword.set_description}
  --*/
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2;

procedure set_heading (
  --/** Sets a new heading for the keyword
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id
  --    @param heading            The new heading
  --    @see {content_keyword.get_heading}, {content_keyword.set_description}
  --*/
  keyword_id  in cr_keywords.keyword_id%TYPE,
  heading     in cr_keywords.heading%TYPE
);

procedure set_description (
  --/** Sets a new description for the keyword
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id
  --    @param description        The new description
  --    @see {content_keyword.set_heading}, {content_keyword.get_description}
  --*/
  keyword_id  in cr_keywords.keyword_id%TYPE,
  description in cr_keywords.description%TYPE
);

function is_leaf (
  --/** Determines if the keyword has no sub-keywords associated with it
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id
  --    @return 't' if the keyword has no descendants, 'f' otherwise
  --    @see {content_keyword.new}
  --*/
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2;

procedure item_assign (
  --/** Assigns this keyword to a content item, creating a relationship between them
  --    @author Karl Goldstein
  --    @param item_id            The item to be assigned to
  --    @param keyword_id         The keyword to be assigned
  --    @param context_id         As in <tt>acs_rel.new</tt>, deprecated
  --    @param creation_ip        As in <tt>acs_rel.new</tt>, deprecated
  --    @param creation_user      As in <tt>acs_rel.new</tt>, deprecated
  --    @see {acs_rel.new}, {content_keyword.item_unassign}
  --*/
  item_id       in cr_items.item_id%TYPE,
  keyword_id    in cr_keywords.keyword_id%TYPE, 
  context_id	in acs_objects.context_id%TYPE default null,
  creation_user in acs_objects.creation_user%TYPE default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null
);

procedure item_unassign (
  --/** Unassigns this keyword to a content item, removing a relationship between them
  --    @author Karl Goldstein
  --    @param item_id            The item to be unassigned from
  --    @param keyword_id         The keyword to be unassigned
  --    @see {acs_rel.delete}, {content_keyword.item_assign}
  --*/
  item_id     in cr_items.item_id%TYPE,
  keyword_id  in cr_keywords.keyword_id%TYPE 
);  

function is_assigned (
  --/** Determines if the keyword is assigned to the item
  --    @author Karl Goldstein
  --    @param item_id            The item id
  --    @param keyword_id         The keyword id to be checked for assignment
  --    @param recurse            Specifies if the keyword search is 
  --                              recursive. May be set to one of the following
  --                              values:<ul>
  --     <li><b>none</b>: Not recursive. Look for an exact match.</li>
  --     <li><b>up</b>: Recursive from specific to general. A search for 
  --       "attack dogs" will also match "dogs", "animals", "mammals", etc.</li>
  --     <li><b>down</b>: Recursive from general to specific. A search for
  --       "mammals" will also match "dogs", "attack dogs", "cats", "siamese cats",
  --       etc.</li></ul>
  --    @return 't' if the keyword may be matched to an item, 'f' otherwise
  --    @see {content_keyword.item_assign}
  --*/
  item_id      in cr_items.item_id%TYPE,
  keyword_id   in cr_keywords.keyword_id%TYPE,
  recurse      in varchar2 default 'none'
) return varchar2;

function get_path (
  --/** Retreives a path to the keyword/subject category, with the most general 
  --    category at the root of the path
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id 
  --    @return The path to the keyword, or null if no such keyword exists
  --    @see {content_keyword.new}
  --*/
  keyword_id in cr_keywords.keyword_id%TYPE
) return varchar2;

end content_keyword;
/
show errors



-- recreate content keyword package body for package_id

create or replace package body content_keyword
as

function get_heading (
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2
is
  v_heading varchar2(4000);
begin

  select heading into v_heading from cr_keywords
    where keyword_id = content_keyword.get_heading.keyword_id;

  return v_heading;
end get_heading;

function get_description (
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2
is
  v_description varchar2(4000);
begin

  select description into v_description from cr_keywords
    where keyword_id = content_keyword.get_description.keyword_id;

  return v_description;
end get_description;

procedure set_heading (
  keyword_id  in cr_keywords.keyword_id%TYPE,
  heading     in cr_keywords.heading%TYPE
)
is
begin

  update cr_keywords set 
    heading = set_heading.heading
  where
    keyword_id = set_heading.keyword_id;

  update acs_objects
  set title = set_heading.heading
  where object_id = set_heading.keyword_id;

end set_heading;

procedure set_description (
  keyword_id  in cr_keywords.keyword_id%TYPE,
  description in cr_keywords.description%TYPE
)
is
begin

  update cr_keywords set 
    description = set_description.description
  where
    keyword_id = set_description.keyword_id;
end set_description;

function is_leaf (
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2
is
  v_leaf varchar2(1);

  cursor c_leaf_cur is
    select
      'f'
    from 
      cr_keywords k
    where
      k.parent_id = is_leaf.keyword_id;

begin

  open c_leaf_cur;
  fetch c_leaf_cur into v_leaf;
  if c_leaf_cur%NOTFOUND then
    v_leaf := 't';
  end if;
  close c_leaf_cur;

  return v_leaf;
end is_leaf;

function new (
  heading       in cr_keywords.heading%TYPE,
  description   in cr_keywords.description%TYPE default null,
  parent_id     in cr_keywords.parent_id%TYPE default null,
  keyword_id    in cr_keywords.keyword_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  object_type   in acs_object_types.object_type%TYPE default 'content_keyword',
  package_id    in acs_objects.package_id%TYPE
) return cr_keywords.keyword_id%TYPE
is
  v_id integer;
  v_package_id acs_objects.package_id%TYPE;
begin

  if package_id is null then
    v_package_id := acs_object.package_id(new.parent_id);
  else
    v_package_id := package_id;
  end if;

  v_id := acs_object.new (object_id => keyword_id,
                          context_id => parent_id,
                          object_type => object_type,
                          title => heading,
                          package_id => v_package_id,
                          creation_date => creation_date, 
                          creation_user => creation_user, 
                          creation_ip => creation_ip);
    
  insert into cr_keywords 
    (heading, description, keyword_id, parent_id)
  values
    (heading, description, v_id, parent_id);

  return v_id;
end new;

procedure del (
  keyword_id  in cr_keywords.keyword_id%TYPE
)
is
  v_item_id integer;
  cursor c_rel_cur is
    select item_id from cr_item_keyword_map 
    where keyword_id = content_keyword.del.keyword_id;
begin

  open c_rel_cur;
  loop
    fetch c_rel_cur into v_item_id;
    exit when c_rel_cur%NOTFOUND;
    item_unassign(v_item_id, content_keyword.del.keyword_id);
  end loop;
  close c_rel_cur;

  acs_object.del(keyword_id);
end del;

procedure item_assign (
  item_id       in cr_items.item_id%TYPE,
  keyword_id    in cr_keywords.keyword_id%TYPE, 
  context_id	in acs_objects.context_id%TYPE default null,
  creation_user in acs_objects.creation_user%TYPE default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null
) 
is
  v_dummy integer;
begin
  
  -- Do nothing if the keyword is assigned already
  select decode(count(*),0,0,1) into v_dummy from dual 
    where exists (select 1 from cr_item_keyword_map
                   where item_id=item_assign.item_id 
                   and keyword_id=item_assign.keyword_id);

  if v_dummy > 0 then
    -- previous assignment exists 
    return;
  end if;

  insert into cr_item_keyword_map (
    item_id, keyword_id
  ) values (
    item_id, keyword_id
  );

end item_assign;

procedure item_unassign (
  item_id     in cr_items.item_id%TYPE,
  keyword_id  in cr_keywords.keyword_id%TYPE 
) is
begin

  delete from cr_item_keyword_map
    where item_id = item_unassign.item_id 
    and keyword_id = item_unassign.keyword_id;

end item_unassign;

function is_assigned (
  item_id     in cr_items.item_id%TYPE,
  keyword_id  in cr_keywords.keyword_id%TYPE,
  recurse     in varchar2 default 'none'
) return varchar2
is
  v_ret varchar2(1);
begin

  -- Look for an exact match
  if recurse = 'none' then
    declare
    begin
      select 't' into v_ret from cr_item_keyword_map
        where item_id = is_assigned.item_id
        and   keyword_id = is_assigned.keyword_id;
      return 't';
    exception when no_data_found then
      return 'f';    
    end;
  end if;

  -- Look from specific to general
  if recurse = 'up' then
    begin
      select 't' into v_ret from dual where exists (select 1 from
	(select keyword_id from cr_keywords
	   connect by parent_id = prior keyword_id
	   start with keyword_id = is_assigned.keyword_id
	 ) t, cr_item_keyword_map m
      where
	t.keyword_id = m.keyword_id
      and
	m.item_id = is_assigned.item_id);

      return 't';

    exception when no_data_found then
      return 'f';    
    end;
  end if;

  if recurse = 'down' then
    begin
      select 't' into v_ret from dual where exists ( select 1 from
	(select keyword_id from cr_keywords
	   connect by prior parent_id = keyword_id
	   start with keyword_id = is_assigned.keyword_id
	 ) t, cr_item_keyword_map m
      where
	t.keyword_id = m.keyword_id
      and
	m.item_id = is_assigned.item_id);

      return 't';

    exception when no_data_found then
      return 'f';    
    end;
  end if;  

  -- Tried none, up and down - must be an invalid parameter
  raise_application_error (-20000, 'The recurse parameter to ' || 
     'content_keyword.is_assigned should be ''none'', ''up'' or ''down''.');

end is_assigned;

function get_path (
  keyword_id in cr_keywords.keyword_id%TYPE
) return varchar2
is
  v_path     varchar2(4000) := '';
  v_is_found varchar2(1)    := 'f';
  
  cursor c_keyword_cur is 
    select 
      heading
    from (
      select 
        heading, level as tree_level
      from cr_keywords
        connect by prior parent_id = keyword_id
        start with keyword_id = get_path.keyword_id
    ) 
    order by 
      tree_level desc;

  v_heading cr_keywords.heading%TYPE;
begin

  open c_keyword_cur;
  loop
    fetch c_keyword_cur into v_heading;
    exit when c_keyword_cur%NOTFOUND;
    v_is_found := 't';
    v_path := v_path || '/' || v_heading;
  end loop;
  close c_keyword_cur;

  if v_is_found = 'f' then
    return null;
  else
    return v_path;
  end if;
end get_path;

end content_keyword;
/
show errors
