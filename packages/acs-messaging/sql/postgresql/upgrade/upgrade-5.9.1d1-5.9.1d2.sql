
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
   p_is_live boolean,       --default 't'
   p_package_id integer      default null

) RETURNS integer AS $$
DECLARE
        p_creation_date timestamptz := current_timestamp;  -- alias for $13 --default sysdate,
        v_message_id   acs_messages.message_id%TYPE;
        v_revision_id  cr_revisions.revision_id%TYPE;
    BEGIN
        -- -- generate a message id now so we can get an rfc822 message-id
        -- if p_message_id is null then
        --     select nextval('t_acs_object_id_seq') into v_message_id;
        -- else
        --     v_message_id := p_message_id;
        -- end if;

        -- -- need to make this mandatory also - jg
        -- -- this needs to be fixed up, but Oracle doesn't give us a way
        -- -- to get the FQDN

	-- -- vk: get SystemURL parameter and use it to extract domain name
        --  select apm__get_value(package_id, 'SystemURL') into v_system_url
        --   from apm_packages where package_key='acs-kernel';
	-- 	v_idx := position('http://' in v_system_url);
	-- 	v_domain_name := trim (substr(v_system_url, v_idx + 7));

        -- if p_rfc822_id is null then
        --    v_rfc822_id := current_date || '.' || v_message_id || '@' ||
        --        v_domain_name || '.hate';
        -- else
        --     v_rfc822_id := p_rfc822_id;
        -- end if;
    
	-- Antonio Pisano 2016-09-20
	-- rfc822_id MUST come from the tcl, no more
	-- sql tricks to retrieve one if missing.
	-- Motivations:
	-- 1) duplication. We have same logics in acs_mail_lite::generate_message_id
	-- 2) what if SystemURL is https?
	-- 3) empty SystemURL would break General Comments
	if p_rfc822_id is null then
	   RAISE null_value_not_allowed;
        end if;

        v_message_id := content_item__new (
            p_rfc822_id,			  -- 1   name           
            p_parent_id,			  -- 2   parent_id      
            p_message_id,			  -- 3   item_id        
            null,				  -- 4   locale
            p_creation_date,			  -- 5   creation_date  
            p_creation_user,			  -- 6   creation_user  
            p_context_id,			  -- 7   context_id     
            p_creation_ip,			  -- 8   creation_ip    
            p_object_type,			  -- 9   item_subtype   
            'acs_message_revision',		  -- 10  content_type   
            null,				  -- 11  title
            null,				  -- 12  description
            'text/plain',			  -- 13  mime_type
            null,				  -- 14  nls_language
            null,				  -- 15  text
            'text',				  -- 16  storage_type
            p_package_id                          -- 17  package_id
        );

        insert into acs_messages 
            (message_id, reply_to, sent_date, sender, rfc822_id)
        values 
            (v_message_id, p_reply_to, p_sent_date, p_sender, p_rfc822_id);

        -- create an initial revision for the new message
        v_revision_id := acs_message__edit (
            v_message_id,			   -- message_id     
            p_title,				   -- title          
            p_description,			   -- description    
            p_mime_type,			   -- mime_type      
            p_text,				   -- text           
            p_data,				   -- data           
            p_creation_date,			   -- creation_date  
            p_creation_user,			   -- creation_user  
            p_creation_ip,			   -- creation_ip    
            p_is_live				   -- is_live        
        );

        return v_message_id;
END;
$$ LANGUAGE plpgsql;
