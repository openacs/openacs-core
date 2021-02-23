<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="acs_messaging_first_ancestor.acs_message_first_ancestor">      
      <querytext>
      
	select acs_message.first_ancestor(:message_id) as ancestor_id from dual
    
      </querytext>
</fullquery>

</queryset>
