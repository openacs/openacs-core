<?xml version="1.0"?>
<queryset>

<fullquery name="acs_messaging_send_query.insert_messaging_by_query">      
      <querytext>
      
        insert into acs_messages_outgoing
            (message_id, to_address, grouping_id, wait_until)
        select :m__message_id, p.email, q.grouping_id,
               coalesce(q.wait_until, SYSDATE) as wait_until
            from ($query) q, parties p
            where not exists (select 1 from acs_messages_outgoing o
                                  where o.message_id = :m__message_id
                                    and p.email = o.to_address)
              and p.party_id = q.recipient_id
    
      </querytext>
</fullquery>

 
<fullquery name="acs_messaging_process_queue.acs_message_remove_from_queue">      
      <querytext>
      
                delete from acs_messages_outgoing
                    where message_id = :sending_message_id
                        and to_address = :recip_email
            
      </querytext>
</fullquery>

 
</queryset>
