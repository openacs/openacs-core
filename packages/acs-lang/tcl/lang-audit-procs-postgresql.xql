<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <fullquery name="lang::audit::changed_message.lang_message_audit">
    <querytext>
          insert into lang_messages_audit (audit_id, package_key, message_key, locale, old_message, comment_text, overwrite_user,
                                           deleted_p, sync_time, conflict_p, upgrade_status) 
            values (nextval('lang_messages_audit_id_seq'::text), :package_key, :message_key, :locale, :old_message, 
                    :comment, :overwrite_user, :deleted_p, :sync_time, :conflict_p, :upgrade_status) 
    </querytext>
  </fullquery>

</queryset>
