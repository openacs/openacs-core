<?xml version="1.0"?>
<queryset>

<fullquery name="select_description">
    <querytext>
        select lmk.description,
               (select lm.message as message
                from   lang_messages lm
                where    lm.package_key= :package_key
                and    lm.message_key = :message_key
                and    locale = :default_locale) as org_message
        from   lang_message_keys lmk
        where  lmk.package_key = :package_key 
        and    lmk.message_key = :message_key
    </querytext>
</fullquery>
	        
</queryset>
	                            
