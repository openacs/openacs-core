<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>


<fullquery name="select_messages">
    <querytext>

    select lmk.message_key,
           lm1.message as default_message,
           lm2.message as translated_message,
           lmk.description,
           nvl(lm2.deleted_p, 'f') as deleted_p
    from   lang_messages lm1,
           lang_messages lm2,
           lang_message_keys lmk
    where  lmk.package_key = :package_key
    and    lm1.locale = :default_locale
    and    lm1.message_key = lmk.message_key
    and    lm1.package_key = lmk.package_key
    and    lm2.locale (+) = :locale
    and    lm2.message_key (+) = lmk.message_key
    and    lm2.package_key (+) = lmk.package_key
    and    lm1.deleted_p = 'f'
    $where_clause
    order  by upper(lm1.message_key), lm1.message_key

    </querytext>
</fullquery>
</queryset>
