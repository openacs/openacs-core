<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="notification::type::delete.delete_notification_type">
        <querytext>
          begin
            notification_type.del(:type_id);
          end;
        </querytext>
    </fullquery>

</queryset>
