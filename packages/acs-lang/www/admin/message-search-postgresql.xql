<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="select_messages">
    <querytext>

        select lm1.message_key,
               lm1.package_key,
               lm1.message as default_message,
               coalesce(lm2.message, 'TRANSLATION MISSING') as translated_message
        from   lang_messages lm1 left outer join 
               lang_messages lm2 on (lm2.locale = :locale and lm2.message_key = lm1.message_key and lm2.package_key = lm1.package_key)
        where  lm1.locale = :default_locale
        and    exists (select 1
                       from   lang_messages lm3
                       where  lm3.locale = :search_locale
                       and    lm3.message_key = lm1.message_key
                       and    lm3.package_key = lm1.package_key
                       and    lm3.message ilike :search_string)
        order by upper(lm1.message_key)

    </querytext>
</fullquery>
	        
</queryset>
	                            
