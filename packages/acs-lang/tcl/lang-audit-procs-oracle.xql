<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="lang::audit::changed_message.lang_message_audit">
    <querytext>
          insert into lang_messages_audit (audit_id, package_key, message_key, locale, old_message, comment_text, overwrite_user,
                                           deleted_p, sync_time, conflict_p, upgrade_status) 
            values (lang_messages_audit_id_seq.nextval, :package_key, :message_key, :locale, empty_clob(), empty_clob(), 
                    :overwrite_user, :deleted_p, :sync_time, :conflict_p, :upgrade_status)  
          returning old_message, comment_text into :1, :2
    </querytext>
  </fullquery>

</queryset>



