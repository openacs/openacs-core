<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <fullquery name="lang::catalog::export.update_sync_time">
    <querytext>
      update lang_messages
      set sync_time = current_timestamp
      where package_key = :package_key
      and locale = :locale
    </querytext>
  </fullquery>


  <fullquery name="lang::catalog::last_sync_messages.last_sync_messages">
    <querytext>
        select message_key,
               message,
               deleted_p
        from   lang_messages
        where  package_key = :package_key
        and    locale = :locale
        and    sync_time is not null
        union
        select lma1.message_key,
               lma1.old_message,
               lma1.deleted_p
        from   lang_messages_audit lma1
        where  lma1.package_key = :package_key
        and    lma1.locale = :locale
        and    lma1.sync_time is not null
        and    lma1.audit_id = (select max(lma2.audit_id)
                                      from lang_messages_audit lma2
                                      where lma2.package_key = lma1.package_key
                                        and lma2.message_key = lma1.message_key
                                        and lma2.locale = :locale
                                        and lma2.sync_time is not null
                                      )
        and    not exists (select 1
                           from lang_messages
                           where package_key = lma1.package_key
                             and message_key = lma1.message_key
                             and locale = :locale
                             and sync_time is not null
                           )
    </querytext>
  </fullquery>
    

</queryset>
