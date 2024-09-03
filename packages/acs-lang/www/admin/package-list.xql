<?xml version="1.0"?>
<queryset>

  <fullquery name="packages_locale_status">
    <querytext>

        select
            package_key,
            count(*)                                                                    as num_messages,
            count(message_is_not_null + messages_not_deleted)                           as num_translated,
            count(message_is_null + default_message_not_deleted + message_not_deleted)  as num_untranslated,
            count(any_message_deleted)                                                  as num_deleted
        from (
            select
                lm1.package_key,
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
                    and lm2.message_key = lm1.message_key
                    and lm2.package_key = lm1.package_key
                )
            where
                lm1.locale = :default_locale
        ) lang_messages
        group by package_key
        order by package_key;

    </querytext>
  </fullquery>

  <fullquery name="packages_locale_status_default">
    <querytext>

        select
            package_key,
            count(*)                                            as num_messages,
            count(message_is_not_null + message_not_deleted)    as num_translated,
            count(message_is_null + message_not_deleted)        as num_untranslated,
            count(message_deleted)                              as num_deleted
        from (
            select
                package_key,
                case when message is null     then 1 end message_is_null,
                case when message is not null then 1 end message_is_not_null,
                case when deleted_p = 't'     then 1 end message_deleted,
                case when deleted_p = 'f'     then 1 end message_not_deleted
            from
                lang_messages
            where
                locale = :default_locale
        ) lang_messages
        group by package_key
        order by package_key;

    </querytext>
  </fullquery>

</queryset>
