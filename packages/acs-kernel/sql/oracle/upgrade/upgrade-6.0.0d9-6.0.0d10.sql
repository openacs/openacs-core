-- Allow responsive images without replacing customized HTML attribute lists.
-- Append only missing attributes; wildcard lists already permit everything.
-- Direct SQL changes require a server restart to clear parameter caches.

update apm_parameters
   set default_value = case when default_value is null or default_value = ''
                           then 'srcset'
                           else default_value || ' srcset' end
 where package_key = 'acs-kernel'
   and parameter_name = 'AllowedAttribute'
   and not regexp_like(coalesce(default_value, ' '), '(^|[[:space:]])(srcset|[*])([[:space:]]|$)');

update apm_parameter_values
   set attr_value = case when attr_value is null or attr_value = ''
                           then 'srcset'
                           else attr_value || ' srcset' end
 where parameter_id in (
       select parameter_id from apm_parameters
        where package_key = 'acs-kernel'
          and parameter_name = 'AllowedAttribute'
   )
   and not regexp_like(coalesce(attr_value, ' '), '(^|[[:space:]])(srcset|[*])([[:space:]]|$)');

update apm_parameters
   set default_value = case when default_value is null or default_value = ''
                           then 'sizes'
                           else default_value || ' sizes' end
 where package_key = 'acs-kernel'
   and parameter_name = 'AllowedAttribute'
   and not regexp_like(coalesce(default_value, ' '), '(^|[[:space:]])(sizes|[*])([[:space:]]|$)');

update apm_parameter_values
   set attr_value = case when attr_value is null or attr_value = ''
                           then 'sizes'
                           else attr_value || ' sizes' end
 where parameter_id in (
       select parameter_id from apm_parameters
        where package_key = 'acs-kernel'
          and parameter_name = 'AllowedAttribute'
   )
   and not regexp_like(coalesce(attr_value, ' '), '(^|[[:space:]])(sizes|[*])([[:space:]]|$)');
