<?xml version="1.0"?>
<queryset>

  <fullquery name="packages_locale_status">
    <querytext>

        select q.*,
               (select count(*)
                    from   lang_messages lm1 left outer join
                           lang_messages lm2 on
                                (lm2.locale = :current_locale
                                and lm2.message_key = lm1.message_key
                                and lm2.package_key = lm1.package_key),
                           lang_message_keys lmk
                    where  lm1.locale = :default_locale
                    and    lm1.package_key = q.package_key
                    and    lm1.message_key = lmk.message_key
                    and    lm1.package_key = lmk.package_key
                    and    lm2.message is not null
                    and    lm1.deleted_p = 'f'
                    and    lm2.deleted_p = 'f'
               ) as num_translated,
               (select count(*)
                    from   lang_messages lm1 left outer join
                           lang_messages lm2 on
                                (lm2.locale = :current_locale
                                and lm2.message_key = lm1.message_key
                                and lm2.package_key = lm1.package_key),
                           lang_message_keys lmk
                    where  lm1.locale = :default_locale
                    and    lm1.package_key = q.package_key
                    and    lm1.message_key = lmk.message_key
                    and    lm1.package_key = lmk.package_key
                    and    lm2.message is null
                    and    lm1.deleted_p = 'f'
                    and    (lm2.deleted_p = 'f' or lm2.deleted_p is null)
               ) as num_untranslated,
               (select count(*)
                    from   lang_messages lm1 left outer join
                           lang_messages lm2 on
                                (lm2.locale = :current_locale
                                and lm2.message_key = lm1.message_key
                                and lm2.package_key = lm1.package_key),
                           lang_message_keys lmk
                    where  lm1.locale = :default_locale
                    and    lm1.package_key = q.package_key
                    and    lm1.message_key = lmk.message_key
                    and    lm1.package_key = lmk.package_key
                    and    (lm1.deleted_p = 't' or lm2.deleted_p = 't')
               ) as num_deleted
        from   (select package_key,
                       count(message_key) as num_messages
                from   lang_messages
                where  locale = :default_locale
                group  by package_key
               ) q
        order  by package_key

    </querytext>
  </fullquery>

  <fullquery name="packages_locale_status_default">
    <querytext>

        select q.*,
               (select count(*)
                    from   lang_messages
                    where  package_key = q.package_key
                    and    locale = :default_locale
                    and    message is not null
                    and    deleted_p = 'f'
               ) as num_translated,
               (select count(*)
                    from   lang_messages
                    where  package_key = q.package_key
                    and    locale = :default_locale
                    and    message is null
                    and    deleted_p = 'f'
               ) as num_untranslated,
               (select count(*)
                    from   lang_messages
                    where  package_key = q.package_key
                    and    locale = :default_locale
                    and    deleted_p = 't'
               ) as num_deleted
        from   (select package_key,
                       count(message_key) as num_messages
                from   lang_messages
                where  locale = :default_locale
                group  by package_key
               ) q
        order  by package_key

    </querytext>
  </fullquery>

</queryset>
