<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::type::delete.delete_notification_type">
        <querytext>
            select notification_type__delete(:type_id)
        </querytext>
    </fullquery>

</queryset>
