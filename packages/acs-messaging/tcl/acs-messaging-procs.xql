<?xml version="1.0"?>
<queryset>

<fullquery name="acs_messaging_process_queue.acs_message_remove_from_queue">      
      <querytext>
      
                delete from acs_messages_outgoing
                    where message_id = :sending_message_id
                        and to_address = :recip_email
            
      </querytext>
</fullquery>

 
</queryset>
