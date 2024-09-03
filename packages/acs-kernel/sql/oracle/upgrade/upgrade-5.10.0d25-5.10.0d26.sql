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

create or replace procedure inline_0 (
  object_type in varchar2,
  attribute_name in varchar2
)
is
  v_attribute_exists integer;
begin
  -- Check that attribute exists
  select decode(count(*),0,0,1) into v_attribute_exists
    from acs_object_types t, acs_attributes a
   where a.object_type = drop_attribute.object_type
     and a.attribute_name = drop_attribute.attribute_name
     and t.object_type = drop_attribute.object_type;

  if v_attribute_exists = 1 then

    -- First remove possible values for the enumeration
    delete from acs_enum_values
     where attribute_id in (select a.attribute_id
                              from acs_attributes a
                             where a.object_type = drop_attribute.object_type
                               and a.attribute_name = drop_attribute.attribute_name);

    -- Finally, get rid of the attribute
    delete from acs_attributes
     where object_type = drop_attribute.object_type
       and attribute_name = drop_attribute.attribute_name;

  end if;

end inline0;
/

select inline_0('apm_package','package_uri') from dual;
select inline_0('apm_package','spec_file_path') from dual;
select inline_0('apm_package','spec_file_mtime') from dual;
select inline_0('apm_package','singleton_p') from dual;
select inline_0('apm_package','initial_install_p') from dual;

drop procedure inline_0;

commit;
