<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="notification::request::delete.delete_request">
<querytext>
declare begin
  notification_request.delete(request_id => :request_id);
end;
</querytext>
</fullquery>

</queryset>
