<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs_message_p.acs_message_p">      
      <querytext>
	    select acs_message__message_p(:message_id);
      </querytext>
</fullquery>
 
<fullquery name="acs_messaging_first_ancestor.acs_message_first_ancestor">
    <querytext>
        select acs_message__first_ancestor(:message_id) as ancestor_id 
    </querytext>
</fullquery>
 
</queryset>
