create or replace function apm_package__is_child(varchar, varchar) returns boolean as '
declare
  parent_package_key       alias for $1;
  child_package_key        alias for $2;
  dependency               record;
begin

  if parent_package_key = child_package_key then
    return ''t'';
  end if;

  for dependency in 
    select apd.service_uri
    from apm_package_versions apv, apm_package_dependencies apd
    where apd.version_id = apv.version_id
      and apv.enabled_p
      and apd.dependency_type in (''embeds'', ''extends'')
      and apv.package_key = child_package_key
  loop
    if dependency.service_uri = parent_package_key or
      apm_package__is_child(parent_package_key, dependency.service_uri) then
      return ''t'';
    end if;
  end loop;
      
  return ''f'';
end;' language 'plpgsql';

