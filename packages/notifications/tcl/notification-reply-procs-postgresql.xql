<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::reply::delete.delete_reply">
        <querytext>
            select notification_reply__delete(:reply_id)
        </querytext>
    </fullquery>

</queryset>
