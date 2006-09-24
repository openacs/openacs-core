alter table acs_object_types alter column table_name drop not null;
alter table acs_object_types alter column id_column drop not null;

create or replace function apm_package__delete (integer) returns integer as '
declare
   delete__package_id   alias for $1;
   cur_val              record;
   v_folder_row         record;
begin
    -- Delete all parameters.
    for cur_val in select value_id from apm_parameter_values
	where package_id = delete__package_id loop
    	PERFORM apm_parameter_value__delete(cur_val.value_id);
    end loop;    

   -- Delete the folders
    for v_folder_row in select
        folder_id
        from cr_folders
        where package_id = delete__package_id
    loop
        perform content_folder__del(v_folder_row.folder_id,''t'');
    end loop;

    delete from apm_applications where application_id = delete__package_id;
    delete from apm_services where service_id = delete__package_id;
    delete from apm_packages where package_id = delete__package_id;
    -- Delete the site nodes for the objects.
    for cur_val in select node_id from site_nodes
	where object_id = delete__package_id loop
    	PERFORM site_node__delete(cur_val.node_id);
    end loop;

    -- Delete the object.
    PERFORM acs_object__delete (
       delete__package_id
    );   

    return 0;
end;' language 'plpgsql';

-- procedure drop_type
create or replace function acs_object_type__drop_type (varchar,boolean)
returns integer as '
declare
  drop_type__object_type            alias for $1;  
  drop_type__cascade_p              alias for $2;  -- default ''f''
  row                               record;
  object_row                        record;
begin

   if drop_type__cascade_p then
     for object_row in select object_id
                         from acs_objects
                         where object_type = drop_type__object_type
     loop
       PERFORM acs_object__delete (object_row.object_id);
     end loop;
   end if;

    -- drop all the attributes associated with this type
    for row in select attribute_name 
                 from acs_attributes 
                where object_type = drop_type__object_type 
    loop
       PERFORM acs_attribute__drop_attribute (drop_type__object_type, 
                                              row.attribute_name);
    end loop;

    delete from acs_attributes
    where object_type = drop_type__object_type;

    delete from acs_object_types
    where object_type = drop_type__object_type;

    return 0; 
end;' language 'plpgsql';

