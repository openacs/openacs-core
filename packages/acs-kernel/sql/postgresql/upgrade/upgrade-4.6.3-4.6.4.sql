--
-- Upgrade script for version 4.6.3 to 4.6.4
--
-- Adds password expiration
--
-- @author Lars Pind (lars@collaboraid.biz)
-- @creation-date 2003-05-28
-- @cvs-id $Id$
--


-- add the column

alter table users add password_changed_date timestamptz ;

alter table users alter column password_changed_date set default now();

-- looks like you cannot add a not null constraint to PG
--alter table users add constraint users_pwd_chg_date_nn (password_changed_date not null);


-- set default value to today

update users set password_changed_date = current_timestamp;


-- recreate the registered_users view

drop view registered_users CASCADE;

create view registered_users
as
  select p.email, p.url, pe.first_names, pe.last_name, u.*, mr.member_state
  from parties p, persons pe, users u, group_member_map m, membership_rels mr, acs_magic_objects amo
  where party_id = person_id
  and person_id = user_id
  and u.user_id = m.member_id
  and m.rel_id = mr.rel_id
  and amo.name = 'registered_users'
  and m.group_id = amo.object_id
  and mr.member_state = 'approved'
  and u.email_verified_p = 't';

create view registered_users_of_package_id
as
SELECT u.*, au.package_id
FROM application_users au, registered_users u
WHERE (au.user_id = u.user_id);

-- recreate the cc_users view

drop view cc_users CASCADE;

create view cc_users
as
select o.*, pa.*, pe.*, u.*, mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr, acs_magic_objects amo
where o.object_id = pa.party_id
  and pa.party_id = pe.person_id
  and pe.person_id = u.user_id
  and u.user_id = m.member_id
  and amo.name = 'registered_users'
  and m.group_id = amo.object_id
  and m.rel_id = mr.rel_id
  and m.container_id = m.group_id;

create view cc_users_of_package_id
as
SELECT u.*, au.package_id
FROM application_users au, cc_users u
WHERE (au.user_id = u.user_id);


-- Fixing a really lame = null bug in this proc that would cause default values
-- of new parameters to not be propagated to package instances
create or replace function apm__register_parameter (integer,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  register_parameter__parameter_id           alias for $1;  -- default null  
  register_parameter__package_key            alias for $2;  
  register_parameter__parameter_name         alias for $3;  
  register_parameter__description            alias for $4;  -- default null  
  register_parameter__datatype               alias for $5;  -- default ''string''  
  register_parameter__default_value          alias for $6;  -- default null  
  register_parameter__section_name           alias for $7;  -- default null 
  register_parameter__min_n_values           alias for $8;  -- default 1
  register_parameter__max_n_values           alias for $9;  -- default 1

  v_parameter_id         apm_parameters.parameter_id%TYPE;
  cur_val                record;
begin
    -- Create the new parameter.    
    v_parameter_id := acs_object__new(
       register_parameter__parameter_id,
       ''apm_parameter'',
       now(),
       null,
       null,
       null
    );
    
    insert into apm_parameters 
    (parameter_id, parameter_name, description, package_key, datatype, 
    default_value, section_name, min_n_values, max_n_values)
    values
    (v_parameter_id, register_parameter__parameter_name, 
     register_parameter__description, register_parameter__package_key, 
     register_parameter__datatype, register_parameter__default_value, 
     register_parameter__section_name, register_parameter__min_n_values, 
     register_parameter__max_n_values);

    -- Propagate parameter to new instances.	
    for cur_val in select ap.package_id, p.parameter_id, p.default_value 
       from apm_parameters p left outer join apm_parameter_values v 
             using (parameter_id), apm_packages ap
      where p.package_key = ap.package_key
        and v.attr_value is null
        and p.package_key = register_parameter__package_key
      loop
      	PERFORM apm__set_value(
	    cur_val.parameter_id, 
	    cur_val.package_id,
	    cur_val.default_value
	    ); 	
      end loop;	
	
    return v_parameter_id;
   
end;' language 'plpgsql';
