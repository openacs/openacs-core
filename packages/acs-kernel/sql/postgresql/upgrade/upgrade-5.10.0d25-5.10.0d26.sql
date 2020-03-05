--
-- Attribute discrepancy fix for object_types in OpenACS:
--
-- Some attributes are not created for new instances since 2006, but an upgrade
-- script deleting the already existing ones was never done.
--
-- This one tries to fix this.
--
-- Original datatype change:
-- https://fisheye.openacs.org/changelog/OpenACS?cs=MAIN%3Avictorg%3A20060727200933
-- https://github.com/openacs/openacs-core/commit/7e30fa270483dcbc866ffbf6f5cf4f30447987cb
--

begin;

CREATE OR REPLACE FUNCTION inline_0(
   p_object_type varchar,
   p_attribute_name varchar

) RETURNS integer AS $$
DECLARE
  v_table_name             acs_object_types.table_name%TYPE;
BEGIN

  -- Check that attribute exists
  select t.table_name into v_table_name
    from acs_object_types t, acs_attributes a
   where a.object_type = p_object_type
     and a.attribute_name = p_attribute_name
     and t.object_type = p_object_type;

  if found then

    -- First remove possible values for the enumeration
    delete from acs_enum_values
    where attribute_id in (select a.attribute_id
                           from acs_attributes a
                           where a.object_type = p_object_type
                           and a.attribute_name = p_attribute_name);

    -- Finally, get rid of the attribute
    delete from acs_attributes
    where object_type = p_object_type
    and attribute_name = p_attribute_name;

  end if;

  return null;
END;
$$ LANGUAGE plpgsql;

select inline_0('apm_package','package_uri');
select inline_0('apm_package','spec_file_path');
select inline_0('apm_package','spec_file_mtime');
select inline_0('apm_package','singleton_p');
select inline_0('apm_package','initial_install_p');

drop function inline_0(varchar,varchar);

end;
