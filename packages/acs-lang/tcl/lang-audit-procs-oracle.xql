<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="lang::audit::changed_message.lang_message_audit">
    <querytext>
          insert into lang_messages_audit (package_key, message_key, locale, old_message, comment_text, overwrite_user) 
            values (:package_key, :message_key, :locale, empty_clob(), empty_clob(), :overwrite_user) 
          returning old_message, comment_text into :1, :2
    </querytext>
  </fullquery>

</queryset>



