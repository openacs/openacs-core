<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="notification::reply::delete.delete_reply">
        <querytext>
            declare begin
                notification_reply.del(reply_id => :reply_id);
            end;
        </querytext>
    </fullquery>

</queryset>
