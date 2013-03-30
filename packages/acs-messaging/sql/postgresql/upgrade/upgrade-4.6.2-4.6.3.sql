-- DRB: The drop is needed otherwise we'll get ambiguous function
-- errors on calls from query files using bindvar emulation, where
-- all the parameters are quoted and therefore of unknown type.



-- added
select define_function_args('acs_message__new','message_id,reply_to,sent_date,sender,rfc822_id,title,description,mime_type,text,data,parent_id,context_id,creation_user,creation_ip,object_type,is_live');

--
-- procedure acs_message__new/16
--
CREATE OR REPLACE FUNCTION acs_message__new(
   p_message_id integer,    --default null,
   p_reply_to integer,      --default null,
   p_sent_date timestamptz, --default sysdate,
   p_sender integer,        --default null,
   p_rfc822_id varchar,     --default null,
   p_title varchar,         --default null,
   p_description varchar,   --default null,
   p_mime_type varchar,     --default 'text/plain',
   p_text text,             --default null,
   p_data integer,          --default null,
   p_parent_id integer,     --default 0,
   p_context_id integer,
   p_creation_user integer, --default null,
   p_creation_ip varchar,   --default null,
   p_object_type varchar,   --default 'acs_message',
   p_is_live boolean        --default 't'

) RETURNS integer AS $$
DECLARE
        p_creation_date timestamptz := current_timestamp;  -- alias for $13 --default sysdate,
        v_message_id   acs_messages.message_id%TYPE;
        v_rfc822_id    acs_messages.rfc822_id%TYPE;
        v_revision_id  cr_revisions.revision_id%TYPE;
		v_system_url   varchar;
		v_domain_name  varchar;
		v_idx		   integer;
    BEGIN
        -- generate a message id now so we can get an rfc822 message-id
        if p_message_id is null then
            select acs_object_id_seq.nextval into v_message_id;
        else
            v_message_id := p_message_id;
        end if;

        -- need to make this mandatory also - jg
        -- this needs to be fixed up, but Oracle doesn't give us a way
        -- to get the FQDN

	-- vk: get SystemURL parameter and use it to extract domain name
         select apm__get_value(package_id, 'SystemURL') into v_system_url
          from apm_packages where package_key='acs-kernel';
		v_idx := position('http://' in v_system_url);
		v_domain_name := trim (substr(v_system_url, v_idx + 7));

        if p_rfc822_id is null then
           v_rfc822_id := current_date || '.' || v_message_id || '@' ||
               v_domain_name || '.hate';
        else
            v_rfc822_id := p_rfc822_id;
        end if;

        v_message_id := content_item__new (
            v_rfc822_id,				  -- name           
            p_parent_id,				  -- parent_id      
            p_message_id,				  -- item_id        
            null,						  -- locale
            p_creation_date,			  -- creation_date  
            p_creation_user,			  -- creation_user  
            p_context_id,				  -- context_id     
            p_creation_ip,				  -- creation_ip    
            p_object_type,				  -- item_subtype   
            'acs_message_revision',	  -- content_type   
            null,						  -- title
            null,						  -- description
            'text/plain',				  -- mime_type
            null,						  -- nls_language
            null,						  -- text
            'text'					  -- storage_type
        );

        insert into acs_messages 
            (message_id, reply_to, sent_date, sender, rfc822_id)
        values 
            (v_message_id, p_reply_to, p_sent_date, p_sender, v_rfc822_id);

        -- create an initial revision for the new message
        v_revision_id := acs_message__edit (
            v_message_id,				   -- message_id     
            p_title,					   -- title          
            p_description,				   -- description    
            p_mime_type,				   -- mime_type      
            p_text,						   -- text           
            p_data,						   -- data           
            p_creation_date,			   -- creation_date  
            p_creation_user,			   -- creation_user  
            p_creation_ip,				   -- creation_ip    
            p_is_live					   -- is_live        
        );

        return v_message_id;
END;
$$ LANGUAGE plpgsql;

