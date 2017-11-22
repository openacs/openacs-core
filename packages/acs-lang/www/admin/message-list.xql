<?xml version="1.0"?>
<queryset>
  <fullquery name="select_messages">
    <querytext>

    select lm1.message_key,
           lm1.message as default_message,
           lm2.message as translated_message,
           lmk.description,
           coalesce(lm2.deleted_p, 'f') as deleted_p
    from   lang_messages lm1 left outer join
           lang_messages lm2 on (lm2.locale = :locale and lm2.message_key = lm1.message_key and lm2.package_key = lm1.package_key),
           lang_message_keys lmk
    where  lm1.locale = :default_locale
    and    lm1.package_key = :package_key
    and    lm1.message_key = lmk.message_key
    and    lm1.package_key = lmk.package_key
    $where_clause
    order  by upper(lm1.message_key), lm1.message_key

    </querytext>
  </fullquery>

</queryset>
