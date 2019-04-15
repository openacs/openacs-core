<?xml version="1.0"?>
<queryset>

  <fullquery name="count_locale">
    <querytext>

        select
            count(*)                                                                    as num_messages,
            count(message_is_not_null + messages_not_deleted)                           as num_translated,
            count(message_is_null + default_message_not_deleted + message_not_deleted)  as num_untranslated,
            count(any_message_deleted)                                                  as num_deleted
        from (
            select
                case when lm2.message is null                           then 1 end message_is_null,
                case when lm2.message is not null                       then 1 end message_is_not_null,
                case when lm1.deleted_p = 't' or lm2.deleted_p = 't'    then 1 end any_message_deleted,
                case when lm1.deleted_p = 'f' and lm2.deleted_p = 'f'   then 1 end messages_not_deleted,
                case when lm1.deleted_p = 'f'                           then 1 end default_message_not_deleted,
                case when lm2.deleted_p = 'f' or lm2.deleted_p is null  then 1 end message_not_deleted
            from
                lang_messages lm1 left outer join
                lang_messages lm2 on (
                        lm2.locale      = :current_locale
                    and lm1.package_key = :package_key
                    and lm2.message_key = lm1.message_key
                    and lm2.package_key = lm1.package_key
                )
            where
                lm1.locale = :default_locale
            and
                lm1.package_key = :package_key
        ) lang_messages;

    </querytext>
  </fullquery>

  <fullquery name="count_locale_default">
    <querytext>

        select
            count(*)                                            as num_messages,
            count(message_is_not_null + message_not_deleted)    as num_translated,
            count(message_is_null + message_not_deleted)        as num_untranslated,
            count(message_deleted)                              as num_deleted
        from (
            select
                case when message is null     then 1 end message_is_null,
                case when message is not null then 1 end message_is_not_null,
                case when deleted_p = 't'     then 1 end message_deleted,
                case when deleted_p = 'f'     then 1 end message_not_deleted
            from
                lang_messages
            where
                locale = :default_locale
            and
                package_key = :package_key
        ) lang_messages;

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
