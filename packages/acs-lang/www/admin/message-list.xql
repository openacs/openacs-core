<?xml version="1.0"?>
<queryset>
  <fullquery name="count_locale">
    <querytext>

        select count(*)
        from   lang_messages lm1 left outer join
               lang_messages lm2 on
                    (lm2.locale = :locale
                    and lm2.message_key = lm1.message_key
                    and lm2.package_key = lm1.package_key),
               lang_message_keys lmk
        where  lm1.locale = :default_locale
        and    lm1.package_key = :package_key
        and    lm1.message_key = lmk.message_key
        and    lm1.package_key = lmk.package_key
        $where_clause

    </querytext>
  </fullquery>

  <fullquery name="count_locale_default">
    <querytext>

        select count(*)
        from   lang_messages lm
        where  package_key = :package_key
        and    locale = :default_locale
        $where_clause

    </querytext>
  </fullquery>

  <fullquery name="select_messages">
    <querytext>

        select lm1.message_key,
               lm1.message as default_message,
               lm2.message as translated_message,
               lmk.description,
               coalesce(lm1.deleted_p, 'f') as deleted_p,
               coalesce(lm2.deleted_p, 'f') as translation_deleted_p
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

  <fullquery name="select_messages_default">
    <querytext>

        select lm.message_key,
               lm.message as default_message,
               lmk.description,
               coalesce(lm.deleted_p, 'f') as deleted_p,
               coalesce(lm.deleted_p, 'f') as translation_deleted_p
        from   lang_messages lm,
               lang_message_keys lmk
        where  lm.locale = :default_locale
        and    lm.package_key = :package_key
        and    lm.message_key = lmk.message_key
        and    lm.package_key = lmk.package_key
        $where_clause_default
        order  by upper(lm.message_key), lm.message_key

    </querytext>
  </fullquery>

</queryset>
