<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_messages">
    <querytext>

        select lm1.message_key,
               lm1.package_key,
               lm1.message as default_message,
               lm2.message as translated_message
        from   lang_messages lm1,
               lang_messages lm2
        where  lm1.locale = :default_locale
        and    lm2.locale (+) = :locale
        and    lm2.message_key (+) = lm1.message_key
        and    lm2.package_key (+) = lm1.package_key
        and    exists (select 1
                       from   lang_messages lm3
                       where  lm3.locale = :search_locale
                       and    lm3.message_key = lm1.message_key
                       and    lm3.package_key = lm1.package_key
                       and    upper(dbms_lob.substr(lm3.message)) like upper(:search_string))
        order by upper(lm1.message_key)

    </querytext>
</fullquery>

</queryset>
