<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs_message_p.acs_message_p">      
      <querytext>
      FIX ME PLSQL

	begin
	    :1 := acs_message__message_p(:message_id);
	end;
    
      </querytext>
</fullquery>

 
<fullquery name="acs_messaging_first_ancestor.acs_message_first_ancestor">      
      <querytext>
      
	select acs_message__first_ancestor(:message_id) as ancestor_id 
    
      </querytext>
</fullquery>

 
<fullquery name="acs_messaging_process_queue.acs_message_send">      
      <querytext>
      FIX ME OUTER JOIN

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
                 acs_messages_all m,
                 acs_messages_all m2,
                 parties p
            where o.message_id = m.message_id
                and m2.message_id(+) = m.reply_to
                and p.party_id = m.sender
                and wait_until <= current_timestamp
    
      </querytext>
</fullquery>

 
</queryset>
