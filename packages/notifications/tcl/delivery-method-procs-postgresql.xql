<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::delivery::delete.delete">
        <querytext>
            select notification_delivery_method__delete(:delivery_method_id)
        </querytext>
    </fullquery>

</queryset>
