<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="lang::message::register.lang_message_update">
    <querytext>
      update lang_messages
      set    [join $set_clauses ", "]
      where  locale = :locale 
      and    message_key = :message_key
      and    package_key = :package_key
      returning message into :1
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.lang_message_insert">
    <querytext>
      insert into lang_messages ([join $col_clauses ", "]) 
      values ([join $val_clauses ", "])
      returning message into :1
    </querytext>
  </fullquery>

  <partialquery name="lang::message::register.sync_time">
    <querytext>
        sysdate
    </querytext>
  </partialquery>

  <partialquery name="lang::message::register.message">
    <querytext>
        empty_clob()
    </querytext>
  </partialquery>

  <fullquery name="lang::message::update_description.update_description">
    <querytext>
      update lang_message_keys
      set    description = empty_clob()
      where  message_key = :message_key
      and    package_key = :package_key
      returning description into :1
    </querytext>
  </fullquery>

  <partialquery name="lang::message::edit.set_sync_time_now">
      <querytext>
        sync_time = sysdate
      </querytext>
  </partialquery>

</queryset>
