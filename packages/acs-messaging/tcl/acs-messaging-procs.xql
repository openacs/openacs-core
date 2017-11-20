<?xml version="1.0"?>
<queryset>

<fullquery name="acs_messaging_process_queue.acs_message_remove_from_queue">      
      <querytext>
      
                delete from acs_messages_outgoing
                    where message_id = :sending_message_id
                        and to_address = :recip_email
            
      </querytext>
</fullquery>

<fullquery name="acs_messaging_send_query.insert_messaging_by_query">      
      <querytext>
      
        insert into acs_messages_outgoing
            (message_id, to_address, grouping_id, wait_until)
        select :m__message_id, p.email, q.grouping_id,
               coalesce(q.wait_until, current_timestamp) as wait_until
            from ($query) q, parties p
            where not exists (select 1 from acs_messages_outgoing o
                                  where o.message_id = :m__message_id
                                    and p.email = o.to_address)
              and p.party_id = q.recipient_id
    
      </querytext>

</fullquery>

<fullquery name="acs_messaging_process_queue.acs_message_send">      
      <querytext>
        select o.message_id as sending_message_id,
               o.to_address as recip_email,
               p.email as sender_email,
               to_char(m.sent_date, 'Dy, DD Mon YYYY HH24:MI:SS') as sent_date,
               m.rfc822_id,
               m.title,
               m.mime_type,
               m.content,
               m2.rfc822_id as in_reply_to
            from acs_messages_outgoing o,
                 acs_messages_all m left outer join acs_messages_all m2 on (m2.message_id = m.reply_to),
                 parties p
            where o.message_id = m.message_id
                and p.party_id = m.sender
                and wait_until <= current_timestamp
      </querytext>
</fullquery>
 
</queryset>
