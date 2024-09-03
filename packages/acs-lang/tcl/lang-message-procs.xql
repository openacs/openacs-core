<?xml version="1.0"?>
<queryset>

  <fullquery name="lang::message::register.message_key_exists_p">
    <querytext>
       select count(*) 
       from lang_message_keys
       where package_key = :package_key
         and message_key = :message_key  
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.lang_message_insert">      
    <querytext>
      insert into lang_messages ([join $col_clauses ", "]) 
      values ([join $val_clauses ", "])
    </querytext>
  </fullquery>
  
  <fullquery name="lang::message::register.lang_message_update">
    <querytext>
      update lang_messages 
      set    [join $set_clauses ", "]
      where  locale = :locale 
      and    package_key = :package_key
      and    message_key = :message_key
    </querytext>
  </fullquery>

</queryset>
