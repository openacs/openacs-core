<?xml version="1.0"?>

<queryset>

    <fullquery name="notification::type::get_type_id.select_type_id">
        <querytext>
            select type_id
            from notification_types
            where short_name = :short_name
        </querytext>
    </fullquery>

    <fullquery name="notification::type::get.select_notification_type">
        <querytext>
            select type_id,
                   short_name,
                   pretty_name,
                   description
            from notification_types
            where short_name = :short_name
        </querytext>
    </fullquery>

    <fullquery name="notification::type::interval_enable.insert_interval_map">
        <querytext>
            insert
            into notification_types_intervals
            (type_id, interval_id)
            select :type_id,
                   :interval_id
            from dual
            where not exists (select 1
                              from notification_types_intervals
                              where type_id = :type_id
                              and interval_id = :interval_id)
        </querytext>
    </fullquery>

    <fullquery name="notification::type::interval_disable.delete_interval_map">
        <querytext>
            delete
            from notification_types_intervals
            where type_id = :type_id
            and interval_id = :interval_id
        </querytext>
    </fullquery>

    <fullquery name="notification::type::delivery_method_enable.insert_delivery_method_map">
        <querytext>
            insert
            into notification_types_del_methods
            (type_id, delivery_method_id)
            select :type_id,
                   :delivery_method_id
            from dual
            where not exists (select 1
                              from notification_types_del_methods
                              where type_id = :type_id
                              and delivery_method_id = :delivery_method_id)
        </querytext>
    </fullquery>

    <fullquery name="notification::type::delivery_method_disable.delete_delivery_method_map">
        <querytext>
            delete
            from notification_types_del_methods
            where type_id = :type_id
            and delivery_method_id = :delivery_method_id
        </querytext>
    </fullquery>

</queryset>
