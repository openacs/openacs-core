--
-- packages/acs-subsite/sql/application_groups-create.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-02-02
-- @cvs-id $Id$
--


create or replace package application_group
is

 function new (
  group_id              in application_groups.group_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'application_group',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  group_name            in groups.group_name%TYPE,
  package_id            in application_groups.package_id%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 ) return application_groups.group_id%TYPE;

 procedure del (
   group_id     in application_groups.group_id%TYPE
 );

 function group_id_from_package_id (
   package_id    in application_groups.group_id%TYPE,
   no_complain_p in char default 'f'
 ) return char;

end application_group;
/
show errors


create or replace package body application_group
is

 function new (
  group_id              in application_groups.group_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'application_group',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  group_name            in groups.group_name%TYPE,
  package_id            in application_groups.package_id%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return application_groups.group_id%TYPE
 is
  v_group_id application_groups.group_id%TYPE;
 begin
  v_group_id := acs_group.new (
               group_id => group_id,
               object_type => object_type,
               creation_date => creation_date,
               creation_user => creation_user,
               creation_ip => creation_ip,
               email => email,
               url => url,
               group_name => group_name,
               context_id => context_id
           );

  insert into application_groups (group_id, package_id) 
    values (v_group_id, package_id);

  return v_group_id;
 end new;


 procedure del (
    group_id     in application_groups.group_id%TYPE
 )
 is
 begin

   acs_group.del(group_id); 

 end del;

 function group_id_from_package_id (
   package_id    in application_groups.group_id%TYPE,
   no_complain_p in char default 'f'
 ) return char
 is
   v_group_id application_groups.group_id%TYPE;
 begin

   select group_id 
   into v_group_id
   from application_groups 
   where package_id = group_id_from_package_id.package_id;

   return v_group_id;

 exception when no_data_found then

   if no_complain_p != 't' then
     raise_application_error(-20000, 'No group_id found for package ' ||
       package_id || ' (' || acs_object.name(package_id) || ').' );
   end if;

   return null;

 end group_id_from_package_id;

end application_group;
/
show errors


create or replace package subsite_callback as

  function new (
  --/** Registers a new callback. If the same callback exists as
  --    defined in the unique constraint on the table, does 
  --    nothing but returns the existing callback_id.
  -- 
  --    @author Michael Bryzek (mbryzek@arsdigita.com)
  --    @creation-date 2001-02-20
  -- 
  --*/
       callback_id         IN subsite_callbacks.callback_id%TYPE default null,
       event_type          IN subsite_callbacks.event_type%TYPE,
       object_type         IN subsite_callbacks.object_type%TYPE,
       callback		   IN subsite_callbacks.callback%TYPE,
       callback_type       IN subsite_callbacks.callback_type%TYPE,
       sort_order          IN subsite_callbacks.sort_order%TYPE default null
  ) return subsite_callbacks.callback_id%TYPE;

  procedure del (
  --/** Deletes the specified callback
  -- 
  --    @author Michael Bryzek (mbryzek@arsdigita.com)
  --    @creation-date 2001-02-20
  -- 
  --*/
  
       callback_id         IN subsite_callbacks.callback_id%TYPE
  );

end subsite_callback;
/
show errors;



create or replace package body subsite_callback as

  function new (
       callback_id         IN subsite_callbacks.callback_id%TYPE default null,
       event_type          IN subsite_callbacks.event_type%TYPE,
       object_type         IN subsite_callbacks.object_type%TYPE,
       callback		   IN subsite_callbacks.callback%TYPE,
       callback_type       IN subsite_callbacks.callback_type%TYPE,
       sort_order          IN subsite_callbacks.sort_order%TYPE default null
  ) return subsite_callbacks.callback_id%TYPE
  IS
    v_callback_id  subsite_callbacks.callback_id%TYPE;
    v_sort_order   subsite_callbacks.sort_order%TYPE;
  BEGIN

    if new.callback_id is null then
       select acs_object_id_seq.nextval into v_callback_id from dual;
    else
       v_callback_id := new.callback_id;
    end if;
   
    if new.sort_order is null then
       -- Make this the next event for this object_type/event_type combination
       select nvl(max(sort_order),0) + 1 into v_sort_order
         from subsite_callbacks
        where object_type = new.object_type
          and event_type = new.event_type;
    else
       v_sort_order := new.sort_order;
    end if;

    begin 
      insert into subsite_callbacks
      (callback_id, event_type, object_type, callback, callback_type, sort_order)
      values
      (v_callback_id, new.event_type, new.object_type, new.callback, new.callback_type, v_sort_order);
     exception when dup_val_on_index then
      select callback_id into v_callback_id
        from subsite_callbacks
       where event_type = new.event_type
         and object_type = new.object_type
         and callback_type = new.callback_type
         and callback = new.callback;
    end;
    return v_callback_id;

  END new;


  procedure del (
       callback_id         IN subsite_callbacks.callback_id%TYPE
  )
  is
  begin
     delete from subsite_callbacks where callback_id=subsite_callback.del.callback_id;
  end del;

end subsite_callback;
/
show errors;

--
-- packages/acs-subsite/sql/user-profiles-create.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-02-02
-- @cvs-id $Id$
--

create or replace package user_profile
as

  function new (
    profile_id          in user_profiles.profile_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'user_profile',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default null,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return user_profiles.profile_id%TYPE;

  procedure del (
    profile_id      in user_profiles.profile_id%TYPE
  );

end user_profile;
/
show errors


create or replace package body user_profile
as

  function new (
    profile_id          in user_profiles.profile_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'user_profile',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default null,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return user_profiles.profile_id%TYPE
  is
    v_profile_id integer;
  begin

    v_profile_id := membership_rel.new (
	rel_id        => profile_id,
        rel_type      => rel_type,
        object_id_one => object_id_one,
        object_id_two => object_id_two,
        member_state  => member_state,
        creation_user => creation_user,
        creation_ip   => creation_ip
    );
    
    insert into user_profiles (profile_id) values (v_profile_id);

    return v_profile_id;
  end new;

  procedure del (
    profile_id      in user_profiles.profile_id%TYPE
  )
  is
  begin

    membership_rel.del(profile_id);

  end del;

end user_profile;
/
show errors


