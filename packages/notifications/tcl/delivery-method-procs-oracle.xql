<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="notification::delivery::delete.delete">
        <querytext>
            begin
                notification_delivery_method.del(:delivery_method_id);
            end;
        </querytext>
    </fullquery>

</queryset>
