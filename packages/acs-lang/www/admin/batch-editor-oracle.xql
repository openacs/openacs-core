<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_messages">
    <querytext>

    select q2.*
    from   (select rownum as inner_rownum, q.* 
            from   (select lm1.message_key,
                           lm1.package_key,
                           lm1.message as default_message,
                           lm2.message as translated_message,
                           lmk.description
                    from   lang_messages lm1,
                           lang_messages lm2,
                           lang_message_keys lmk
                    where  lm1.locale = :default_locale
                    and    lm2.locale (+) = :locale 
                    and    lm2.message_key (+) = lm1.message_key
                    and    lm2.package_key (+) = lm1.package_key
                    and    lm1.message_key = lmk.message_key
                    and    lm1.package_key = lmk.package_key
                    and    lm1.package_key = :package_key
                    $where_clause
                    order  by upper(lm1.message_key), lm1.message_key
                   ) q
            ) q2
    where  inner_rownum between :page_start + 1 and :page_start + 10
    order  by inner_rownum

    </querytext>
</fullquery>
	        
</queryset>
