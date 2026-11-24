-- Remove obsolete metadata only if the corresponding function is absent.
delete from acs_function_args
 where function = 'CONTENT_ITEM__TRASH_RECOVER_SINGLE_ITEM'
   and not exists (
       select 1 from pg_proc
        where proname = 'content_item__trash_recover_single_item'
          and pg_function_is_visible(oid)
   );
