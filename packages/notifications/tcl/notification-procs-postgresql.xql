<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::delete.delete_notification">
        <querytext>
            select notification__delete(:notification_id)
        </querytext>
    </fullquery>

</queryset>
