<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::request::delete.delete_request">
        <querytext>
            select notification_request__delete(:request_id);
        </querytext>
    </fullquery>

</queryset>
