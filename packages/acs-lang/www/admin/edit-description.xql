<?xml version="1.0"?>
<queryset>

<fullquery name="select_description">
    <querytext>
        select lm.message as message,
               lmk.description
        from   lang_message_keys lmk,
               lang_messages lm
        where  lmk.package_key = lm.package_key 
        and    lmk.message_key = lm.message_key
        and    lm.package_key= :package_key
        and    lm.message_key = :message_key
        and    locale = :locale
    </querytext>
</fullquery>
	        
</queryset>
	                            
