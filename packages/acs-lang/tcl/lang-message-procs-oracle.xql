<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

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

</queryset>
