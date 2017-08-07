-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2004-07-18
-- @arch-tag: e3c4c07f-a3cc-480f-a06f-7ffd30e5606f
-- @cvs-id $Id$
--


create or replace function content_type__drop_attribute (varchar,varchar,boolean)
returns integer as '
declare
  drop_attribute__content_type           alias for $1;  
  drop_attribute__attribute_name         alias for $2;  
  drop_attribute__drop_column            alias for $3;  -- default ''f''  
  v_attr_id                              acs_attributes.attribute_id%TYPE;
  v_table                                acs_object_types.table_name%TYPE;
begin

  -- Get attribute information 
  select 
    upper(t.table_name), a.attribute_id 
  into 
    v_table, v_attr_id
  from 
    acs_object_types t, acs_attributes a
  where 
    t.object_type = drop_attribute__content_type
  and 
    a.object_type = drop_attribute__content_type
  and
    a.attribute_name = drop_attribute__attribute_name;
    
  if NOT FOUND then
    raise EXCEPTION ''-20000: Attribute %:% does not exist in content_type.drop_attribute'', drop_attribute__content_type, drop_attribute__attribute_name;
  end if;

  -- Drop the attribute
  PERFORM acs_attribute__drop_attribute(drop_attribute__content_type, 
                                        drop_attribute__attribute_name);

  -- Drop the column if necessary
  if drop_attribute__drop_column then
      execute ''alter table '' || v_table || '' drop column '' ||
	drop_attribute__attribute_name || '' cascade'';

--    exception when others then
--      raise_application_error(-20000, ''Unable to drop column '' || 
--       v_table || ''.'' || attribute_name || '' in content_type.drop_attribute'');  
  end if;  

  PERFORM content_type__refresh_view(drop_attribute__content_type);

  return 0; 
end;' language 'plpgsql';

