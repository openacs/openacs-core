<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="lang_message_register.lang_message_update">      
      <querytext>
		    update lang_messages set 
		    registered_p = 't' 
                    ,message = empty_clob() 
		    where lang = :lang and key = :key
            returning message into :1
      </querytext>
</fullquery>

 
<fullquery name="lang_message_register.lang_message_insert">      
      <querytext>
		insert into lang_messages (key, lang, message, registered_p) 
		values (:key, :lang, empty_clob(),'t') 
                returning message into :1
      </querytext>
</fullquery>
</queryset>
