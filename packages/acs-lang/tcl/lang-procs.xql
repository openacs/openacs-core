<?xml version="1.0"?>
<queryset>

<fullquery name="lang_message_register.lang_message_update">      
      <querytext>
		    update lang_messages set 
		    registered_p = 't' 
                    ,message = :message 
		    where lang = :lang and key = :key
      </querytext>
</fullquery>

 
<fullquery name="lang_message_register.lang_message_insert">      
      <querytext>
		insert into lang_messages (key, lang, message, registered_p) 
		values (:key, :lang, :message,'t') 
      </querytext>
</fullquery>

 
</queryset>
