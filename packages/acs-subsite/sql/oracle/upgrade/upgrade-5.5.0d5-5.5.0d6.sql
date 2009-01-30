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
  join_policy           in groups.join_policy%TYPE default null,
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
  join_policy           in groups.join_policy%TYPE default null,
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
               context_id => context_id,
               join_policy => join_policy
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

