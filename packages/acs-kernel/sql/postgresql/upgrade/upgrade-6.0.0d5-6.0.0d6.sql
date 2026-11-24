-- Remove registrations left by functions retired in older releases.
delete from acs_function_args a
 where a.function in (
     'ACS_OBJECT__OBJECT_ID',
     'ACS_OBJECTS_GET_TREE_SORTKEY'
 )
   and not exists (
       select 1 from pg_proc p where p.proname = lower(a.function)
   );
