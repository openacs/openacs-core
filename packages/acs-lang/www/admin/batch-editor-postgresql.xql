<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="get_messages">
    <querytext>

    select lm1.message_key,
           lm1.package_key,
           lm1.message as default_message,
           lm2.message as translated_message,
           lmk.description
    from   lang_messages lm1 left outer join 
           lang_messages lm2 on (lm2.locale = :locale and lm2.message_key = lm1.message_key and lm2.package_key = lm1.package_key),
           lang_message_keys lmk
    where  lm1.locale = :default_locale
    and    lm1.package_key = :package_key
    and    lm1.message_key = lmk.message_key
    and    lm1.package_key = lmk.package_key
    $where_clause
    order  by upper(lm1.message_key), lm1.message_key
    offset $page_start
    limit  10

    </querytext>
</fullquery>
	        
</queryset>
	                            
