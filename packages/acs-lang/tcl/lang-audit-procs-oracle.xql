<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="lang::audit::changed_message.lang_message_audit">
    <querytext>
          insert into lang_messages_audit (package_key, message_key, locale, message, overwrite_user) 
            values (:package_key, :message_key, :locale, empty_clob(), :overwrite_user) 
          returning message into :1
    </querytext>
  </fullquery>

</queryset>



