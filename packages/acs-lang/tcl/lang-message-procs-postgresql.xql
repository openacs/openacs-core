<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <partialquery name="lang::message::register.message">
    <querytext>
        :message
    </querytext>
  </partialquery>

  <fullquery name="lang::message::update_description.update_description">
    <querytext>
      update lang_message_keys
      set    description = :description
      where  message_key = :message_key
      and    package_key = :package_key
    </querytext>
  </fullquery>

</queryset>
