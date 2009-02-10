--
-- packages/acs-messaging/sql/acs-messaging-packages.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @author Phong Nguyen <phong@arsdigita.com>
-- @author Jon Griffin <jon@jongriffin.com>
-- @creation-date 2000-08-27
-- @cvs-id $Id$
--
-- updated for OpenACS by Jon Griffin
--

create or replace function acs_message__edit (integer,varchar,varchar,varchar,text,integer,timestamptz,integer,varchar,boolean)
returns integer as '
declare
    p_message_id    alias for $1;
    p_title         alias for $2;    -- default null
    p_description   alias for $3;    -- default null
    p_mime_type     alias for $4;    -- default ''text/plain''
    p_text          alias for $5;    -- default null
    p_data          alias for $6;    -- default null
    p_creation_date alias for $7;    -- default sysdate
    p_creation_user alias for $8;    -- default null
    p_creation_ip   alias for $9;    -- default null
    p_is_live       alias for $10;   -- default ''t''
    v_revision_id cr_revisions.revision_id%TYPE;
begin
    -- create a new revision using whichever call is appropriate
    if p_data is not null then
		-- need to take care of blob?
        v_revision_id := content_revision__new (
            p_message_id,		-- item_id        
            p_title,			-- title          
            p_description,		-- description    
            p_data,			-- data           
            p_mime_type,		-- mime_type      
            p_creation_date,		-- creation_date  
            p_creation_user,		-- creation_user  
            p_creation_ip		-- creation_ip    
        );
    else if p_title is not null or p_text is not null then
        v_revision_id := content_revision__new (
            p_title,			-- title          
            p_description,		-- description    
			now(),		-- publish_date
            p_mime_type,		-- mime_type      
			null,		-- nls_language
            p_text,			-- text           
            p_message_id,		-- item_id        
			null,		-- revision_id
            p_creation_date,		-- creation_date  
            p_creation_user,		-- creation_user  
            p_creation_ip		-- creation_ip    
        );      
    end if;
	end if;

    -- test for auto approval of revision   
    if p_is_live then 
        perform content_item__set_live_revision(v_revision_id);
    end if;

    return v_revision_id;
end;' language 'plpgsql';
   
----------------
-- MAJOR NOTE OF NON-COMPLIANCE
-- I am exercising my rights as the porter here!
-- I can only use 16 parameters so I am changing one
-- creation_date will default to sysdate and not be a parameter
-- possibly another function can be made to change that
-- although I really don't see much need for this.
-- Jon Griffin 05-21-2001
----------------

create or replace function acs_message__new (integer,integer,timestamptz,integer,
varchar,varchar,varchar,varchar,text,integer,integer,integer,integer,
varchar,varchar,boolean,integer)
returns integer as '
declare
        p_message_id    alias for $1;  --default null,
        p_reply_to      alias for $2;  --default null,
        p_sent_date     alias for $3;  --default sysdate,
        p_sender        alias for $4;  --default null,
        p_rfc822_id     alias for $5;  --default null,
        p_title         alias for $6;  --default null,
        p_description   alias for $7;  --default null,
        p_mime_type     alias for $8;  --default ''text/plain'',
        p_text          alias for $9;  --default null,
        p_data          alias for $10; --default null,
        p_parent_id     alias for $11; --default 0,
        p_context_id    alias for $12;
        p_creation_date timestamptz := current_timestamp;  -- alias for $13 --default sysdate,
        p_creation_user alias for $13; --default null,
        p_creation_ip   alias for $14; --default null,
        p_object_type   alias for $15; --default ''acs_message'',
        p_is_live       alias for $16; --default ''t''
        p_package_id    alias for $17;
        v_message_id   acs_messages.message_id%TYPE;
        v_rfc822_id    acs_messages.rfc822_id%TYPE;
        v_revision_id  cr_revisions.revision_id%TYPE;
		v_system_url   varchar;
		v_domain_name  varchar;
		v_idx		   integer;
    begin
        -- generate a message id now so we can get an rfc822 message-id
        if p_message_id is null then
            select nextval(''t_acs_object_id_seq'') into v_message_id;
        else
            v_message_id := p_message_id;
        end if;

        -- need to make this mandatory also - jg
        -- this needs to be fixed up, but Oracle doesn''t give us a way
        -- to get the FQDN

	-- vk: get SystemURL parameter and use it to extract domain name
         select apm__get_value(package_id, ''SystemURL'') into v_system_url
          from apm_packages where package_key=''acs-kernel'';
		v_idx := position(''http://'' in v_system_url);
		v_domain_name := trim (substr(v_system_url, v_idx + 7));

        if p_rfc822_id is null then
           v_rfc822_id := current_date || ''.'' || v_message_id || ''@'' ||
               v_domain_name || ''.hate'';
        else
            v_rfc822_id := p_rfc822_id;
        end if;

        v_message_id := content_item__new (
            v_rfc822_id,			  -- name           
            p_parent_id,			  -- parent_id      
            p_message_id,			  -- item_id        
            null,				  -- locale
            p_creation_date,			  -- creation_date  
            p_creation_user,			  -- creation_user  
            p_context_id,			  -- context_id     
            p_creation_ip,			  -- creation_ip    
            p_object_type,			  -- item_subtype   
            ''acs_message_revision'',		  -- content_type   
            null,				  -- title
            null,				  -- description
            ''text/plain'',			  -- mime_type
            null,				  -- nls_language
            null,				  -- text
            ''text'',				  -- storage_type
            p_package_id
        );

        insert into acs_messages 
            (message_id, reply_to, sent_date, sender, rfc822_id)
        values 
            (v_message_id, p_reply_to, p_sent_date, p_sender, v_rfc822_id);

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
end;' language 'plpgsql';

create or replace function acs_message__new (integer,integer,timestamptz,integer,
varchar,varchar,varchar,varchar,text,integer,integer,integer,integer,
varchar,varchar,boolean)
returns integer as '
declare
        p_message_id    alias for $1;  --default null,
        p_reply_to      alias for $2;  --default null,
        p_sent_date     alias for $3;  --default sysdate,
        p_sender        alias for $4;  --default null,
        p_rfc822_id     alias for $5;  --default null,
        p_title         alias for $6;  --default null,
        p_description   alias for $7;  --default null,
        p_mime_type     alias for $8;  --default ''text/plain'',
        p_text          alias for $9;  --default null,
        p_data          alias for $10; --default null,
        p_parent_id     alias for $11; --default 0,
        p_context_id    alias for $12;
        p_creation_date timestamptz := current_timestamp;  -- alias for $13 --default sysdate,
        p_creation_user alias for $13; --default null,
        p_creation_ip   alias for $14; --default null,
        p_object_type   alias for $15; --default ''acs_message'',
        p_is_live       alias for $16; --default ''t''
begin
    return acs_message__new (p_message_id,
                             p_reply_to,
                             p_sent_date,
                             p_sender,
                             p_rfc822_id,
                             p_title,
                             p_description,
                             p_mime_type,
                             p_text,
                             p_data,
                             p_parent_id,
                             p_context_id,
                             p_creation_user,
                             p_creation_ip,
                             p_object_type,
                             p_is_live,
                             null::integer
   );
end;' language 'plpgsql';

create or replace function acs_message__delete (integer)
returns integer as '
declare
    p_message_id    alias for $1;
begin
    delete from acs_messages where message_id = p_message_id;
    perform content_item__delete(p_message_id);
    return 1;
end;' language 'plpgsql';

create or replace function acs_message__message_p (integer)
returns boolean as '
declare
    p_message_id          alias for $1;
    v_check_message_id  integer;
begin
    select count(message_id) into v_check_message_id
        from acs_messages where message_id = p_message_id;

    if v_check_message_id <> 0 then
        return ''t'';
    else
        return ''f'';
    end if;
end;' language 'plpgsql' stable;

create or replace function acs_message__send (integer,varchar,integer,timestamptz)
returns integer as '
declare
    p_message_id    alias for $1;
    p_to_address    alias for $2;
    p_grouping_id   alias for $3;    -- default null
    p_wait_until    alias for $4;    -- default sysdate
    v_wait_until timestamptz;
begin
    v_wait_until := coalesce(p_wait_until, current_timestamp);
    insert into acs_messages_outgoing
        (message_id, to_address, grouping_id, wait_until)
    values
        (p_message_id, p_to_address, p_grouping_id, v_wait_until);
    return 1;
end;' language 'plpgsql';

create or replace function acs_message__send (integer,integer,integer,timestamptz)
returns integer as '
declare
    p_message_id    alias for $1;
    p_recipient_id  alias for $2;
    p_grouping_id   alias for $3;    -- default null
    p_wait_until    alias for $4;    -- default sysdate
    v_wait_until timestamptz;
begin
    v_wait_until := coalesce (p_wait_until, current_timestamp);
    insert into acs_messages_outgoing
        (message_id, to_address, grouping_id, wait_until)
    select p_message_id, p.email, p_grouping_id, v_wait_until
        from parties p
        where p.party_id = p_recipient_id;
    return 1;
end;' language 'plpgsql';


-- Ported to take advantage of tree_sortkey column by DLP

create or replace function acs_message__first_ancestor (integer)
returns integer as '
declare
    p_message_id alias for $1;
    v_message_id acs_messages.message_id%TYPE;
    v_ancestor_sk varbit;
begin
    select tree_ancestor_key(tree_sortkey, 1) into v_ancestor_sk
      from acs_messages
     where message_id = p_message_id;

    select message_id into v_message_id
      from acs_messages
     where tree_sortkey = v_ancestor_sk;

    return v_message_id;
end;' language 'plpgsql' stable strict;

    -- ACHTUNG!  WARNING!  ACHTUNG!  WARNING!  ACHTUNG!  WARNING! --

    -- Developers: Please don't depend on the following functionality
    -- to remain in the same place.  Chances are very good these
    -- functions will migrate to another PL/SQL package or be replaced
    -- by direct calls to CR code in the near future.

create or replace function acs_message__new_file (integer,integer,varchar,varchar,
text,varchar,integer,timestamptz,integer,varchar,boolean,varchar,integer)
returns integer as '
declare
    p_message_id    alias for $1;
    p_file_id       alias for $2;    -- default null
    p_file_name     alias for $3;
    p_title         alias for $4;    -- default null
    p_description   alias for $5;    -- default null
    p_mime_type     alias for $6;    -- default ''text/plain''
    p_data          alias for $7;    -- default null
    p_creation_date alias for $8;    -- default sysdate
    p_creation_user alias for $9;    -- default null
    p_creation_ip   alias for $10;   -- default null
    p_is_live       alias for $11;   -- default ''t''
    p_storage_type  alias for $12;   -- default ''file''
    p_package_id    alias for $13;   -- default null
    v_file_id      cr_items.item_id%TYPE;
    v_revision_id  cr_revisions.revision_id%TYPE;
begin
    v_file_id := content_item__new (
        p_file_name,			   -- name           
        p_message_id,			   -- parent_id      
        p_file_id,			   -- item_id        
        null,				   -- locale
        p_creation_date,		   -- creation_date  
        p_creation_user,		   -- creation_user  
        null,				   -- context_id
        p_creation_ip,			   -- creation_ip    
        ''content_item'',		   -- item_subtype
        ''content_revision'',		   -- content_type
        null,				   -- title
        null,				   -- description
        ''text/plain'',			   -- mime_type
        null,				   -- nls_language
        null,				   -- text
	p_storage_type,			   -- storage_type
        p_package_id			   -- package_id
    );

    -- create an initial revision for the new attachment
    v_revision_id := acs_message__edit_file (
         v_file_id,			-- file_id        
         p_title,			-- title          
         p_description,			-- description    
         p_mime_type,			-- mime_type      
         p_data,			-- data        
         p_creation_date,		-- creation_date  
         p_creation_user,		-- creation_user  
         p_creation_ip,			-- creation_ip    
         p_is_live			-- is_live        
    );

    return v_file_id;
end;' language 'plpgsql';

create or replace function acs_message__new_file (integer,integer,varchar,varchar,
text,varchar,integer,timestamptz,integer,varchar,boolean,varchar)
returns integer as '
declare
    p_message_id    alias for $1;
    p_file_id       alias for $2;    -- default null
    p_file_name     alias for $3;
    p_title         alias for $4;    -- default null
    p_description   alias for $5;    -- default null
    p_mime_type     alias for $6;    -- default ''text/plain''
    p_data          alias for $7;    -- default null
    p_creation_date alias for $8;    -- default sysdate
    p_creation_user alias for $9;    -- default null
    p_creation_ip   alias for $10;   -- default null
    p_is_live       alias for $11;   -- default ''t''
    p_storage_type  alias for $12;   -- default ''file''
begin
    return acs_message__new_file (p_message_id,
                                  p_file_id,
                                  p_file_name,
                                  p_title,
                                  p_description,
                                  p_mime_type,
                                  p_data,
                                  p_creation_date,
                                  p_creation_user,
                                  p_creation_ip,
                                  p_is_live,
                                  p_storage_type,
                                  null
   );
end;' language 'plpgsql';

create or replace function acs_message__edit_file (integer,varchar,text,varchar,
integer,timestamptz,integer,varchar,boolean)
returns integer as '
declare
    p_file_id       alias for $1;
    p_title         alias for $2;    -- default null
    p_description   alias for $3;    -- default null
    p_mime_type     alias for $4;    -- default ''text/plain''
    p_data          alias for $5;    -- default null
    p_creation_date alias for $6;    -- default sysdate
    p_creation_user alias for $7;    -- default null
    p_creation_ip   alias for $8;    -- default null
    p_is_live       alias for $9;    -- default ''t''
    v_revision_id  cr_revisions.revision_id%TYPE;
begin
    v_revision_id := content_revision__new (
        p_title,			-- title         
        p_description,
        current_timestamp,
        p_mime_type,			-- mime_type     
        NULL,
        p_data,				-- data          
        p_file_id,			-- item_id       
        NULL,
        p_creation_date,		-- creation_date 
        p_creation_user,		-- creation_user 
        p_creation_ip			-- creation_ip   
    );

    -- test for auto approval of revision
    if p_is_live then 
        perform content_item__set_live_revision(v_revision_id);
    end if;

    return v_revision_id;
end;' language 'plpgsql';

create or replace function acs_message__delete_file (integer)
returns integer as '
declare
    p_file_id  alias for $1;
begin
    perform content_item__delete(p_file_id);       
    return 1;
end;' language 'plpgsql';

create or replace function acs_message__new_image (integer,integer,varchar,varchar,
text,varchar,integer,integer,integer,timestamptz,integer,varchar,boolean,varchar,integer)
returns integer as '
declare
    p_message_id     alias for $1;
    p_image_id       alias for $2;    -- default null
    p_file_name      alias for $3;
    p_title          alias for $4;    -- default null
    p_description    alias for $5;    -- default null
    p_mime_type      alias for $6;    -- default ''text/plain''
    p_data           alias for $7;    -- default null
    p_width          alias for $8;    -- default null
    p_height         alias for $9;    -- default null
    p_creation_date  alias for $10;   -- default sysdate
    p_creation_user  alias for $11;   -- default null
    p_creation_ip    alias for $12;   -- default null
    p_is_live        alias for $13;   -- default ''t''
    p_storage_type   alias for $14;   -- default ''file''
    p_package_id     alias for $15;   -- default null
    v_image_id     cr_items.item_id%TYPE;
    v_revision_id  cr_revisions.revision_id%TYPE;
begin
    v_image_id := content_item__new (
         p_file_name,				-- name          
         p_message_id,				-- parent_id     
         p_image_id,				-- item_id       
         null,					-- locale
         p_creation_date,			-- creation_date 
         p_creation_user,			-- creation_user 
         null,					-- context_id
         p_creation_ip,				-- creation_ip
	 ''content_item'',			-- item_subtype
	 ''content_revision'',			-- content_type
	 null,					-- title
	 null,					-- description
	 ''text/plain'',			-- mime_type
	 null,					-- nls_language
	 null,					-- text
	 ''file'',				-- storage_type
         p_package_id				-- package_id
    );

    -- create an initial revision for the new attachment
    v_revision_id := acs_message__edit_image (
         v_image_id,				-- image_id      
         p_title,				-- title         
         p_description,				-- description   
         p_mime_type,				-- mime_type     
         p_data,				-- data       
         p_width,				-- width         
         p_height,				-- height        
         p_creation_date,			-- creation_date 
         p_creation_user,			-- creation_user 
         p_creation_ip,				-- creation_ip   
         p_is_live				-- is_live       
    );

    return v_image_id;
end;' language 'plpgsql';

create or replace function acs_message__new_image (integer,integer,varchar,varchar,
text,varchar,integer,integer,integer,timestamptz,integer,varchar,boolean,varchar)
returns integer as '
declare
    p_message_id     alias for $1;
    p_image_id       alias for $2;    -- default null
    p_file_name      alias for $3;
    p_title          alias for $4;    -- default null
    p_description    alias for $5;    -- default null
    p_mime_type      alias for $6;    -- default ''text/plain''
    p_data           alias for $7;    -- default null
    p_width          alias for $8;    -- default null
    p_height         alias for $9;    -- default null
    p_creation_date  alias for $10;   -- default sysdate
    p_creation_user  alias for $11;   -- default null
    p_creation_ip    alias for $12;   -- default null
    p_is_live        alias for $13;   -- default ''t''
    p_storage_type   alias for $14;   -- default ''file''
begin
    return acs_message__new_image (p_message_id,
                                   p_image_id,
                                   p_file_name,
                                   p_title,
                                   p_description,
                                   p_mime_type,
                                   p_data,
                                   p_width,
                                   p_height,
                                   p_creation_date,
                                   p_creation_user,
                                   p_creation_ip,
                                   p_is_live,
                                   p_storage_type,
                                   null
   );
end;' language 'plpgsql';

create or replace function acs_message__edit_image (integer,varchar,text,varchar,
integer,integer,integer,timestamptz,integer,varchar,boolean)
returns integer as '
declare
    p_image_id       alias for $1;
    p_title          alias for $2;    -- default null
    p_description    alias for $3;    -- default null
    p_mime_type      alias for $4;    -- default ''text/plain''
    p_data           alias for $5;    -- default null
    p_width          alias for $6;    -- default null
    p_height         alias for $7;    -- default null
    p_creation_date  alias for $8;    -- default sysdate
    p_creation_user  alias for $9;    -- default null
    p_creation_ip    alias for $10;   -- default null
    p_is_live        alias for $11;   -- default ''t''
    v_revision_id  cr_revisions.revision_id%TYPE;
begin
		-- not sure which __new to use
    v_revision_id := content_revision__new (
         p_title,             -- title         
         NULL,                -- description
         current_timestamp,   -- publish_date
         p_mime_type,         -- mime_type     
         NULL,                -- nls_language
         p_data,              -- data          
         p_image_id,          -- item_id       
         NULL,                -- revision_id
         p_creation_date,     -- creation_date 
         p_creation_user,     -- creation_user 
         p_creation_ip        -- creation_ip   
    );      

    -- insert new width and height values
    -- XXX fix after image.new exists
    insert into images
        (image_id, width, height)
    values
        (v_revision_id, p_width, p_height);

    -- test for auto approval of revision   
    if p_is_live then 
        perform content_item__set_live_revision(v_revision_id);
    end if;

    return v_revision_id;
end;' language 'plpgsql';

create or replace function acs_message__delete_image (integer)
returns integer as '
declare
    p_image_id  alias for $1;
begin
    perform image__delete(p_image_id);

    return 0;
end;' language 'plpgsql';

    -- XXX should just call content_extlink.new
create or replace function acs_message__new_extlink (varchar,integer,varchar,
varchar,text,integer,timestamptz,integer,varchar,integer)
returns integer as '
declare
    p_name           alias for $1;    -- default null
    p_extlink_id     alias for $2;    -- default null
    p_url            alias for $3;   
    p_label          alias for $4;    -- default null
    p_description    alias for $5;    -- default null
    p_parent_id      alias for $6;
    p_creation_date  alias for $7;    -- default sysdate
    p_creation_user  alias for $8;    -- default null
    p_creation_ip    alias for $9;    -- default null
    p_package_id     alias for $10;   -- default null
    v_extlink_id  cr_extlinks.extlink_id%TYPE;
begin
    v_extlink_id := content_extlink__new (
         p_name,			-- name          
         p_url,				-- url           
         p_label,			-- label         
         p_description,			-- description   
         p_parent_id,			-- parent_id     
         p_extlink_id,			-- extlink_id    
         p_creation_date,		-- creation_date 
         p_creation_user,		-- creation_user 
         p_creation_ip,			-- creation_ip
         p_package_id
    );

	return v_extlink_id;
end;' language 'plpgsql';
    
create or replace function acs_message__new_extlink (varchar,integer,varchar,
varchar,text,integer,timestamptz,integer,varchar)
returns integer as '
declare
    p_name           alias for $1;    -- default null
    p_extlink_id     alias for $2;    -- default null
    p_url            alias for $3;   
    p_label          alias for $4;    -- default null
    p_description    alias for $5;    -- default null
    p_parent_id      alias for $6;
    p_creation_date  alias for $7;    -- default sysdate
    p_creation_user  alias for $8;    -- default null
    p_creation_ip    alias for $9;    -- default null
begin
    return acs_message__new_extlink (p_name,
                                     p_extlink_id,
                                     p_url,
                                     p_label,
                                     p_description,
                                     p_parent_id,
                                     p_creation_date,
                                     p_creation_user,
                                     p_creation_ip,
                                     null
   );
end;' language 'plpgsql';

-- XXX should just edit extlink
create or replace function acs_message__edit_extlink (integer,varchar,varchar,text)
returns integer as '
declare
    p_extlink_id   alias for $1;
    p_url          alias for $2;
    p_label        alias for $3;    -- default null
    p_description  alias for $4;    --  default null
    v_is_extlink   boolean;
begin
    v_is_extlink := content_extlink__is_extlink(p_extlink_id);
    if v_is_extlink = ''t'' then
        update cr_extlinks
        set url = p_url,
            label = p_label,
            description = p_description
        where extlink_id = p_extlink_id;
    end if;
    return 0;
end;' language 'plpgsql';

create or replace function acs_message__delete_extlink (integer)
returns integer as '
declare
    p_extlink_id    alias for $1;
begin
    perform content_extlink__delete(p_extlink_id);

	return 0;
end;' language 'plpgsql';

create or replace function acs_message__name (integer)
returns varchar as '
declare
    p_message_id   alias for $1;
    v_message_name   cr_revisions.title%TYPE;
begin
    select title into v_message_name
        from acs_messages_all
        where message_id = p_message_id;
    return v_message_name;
end;' language 'plpgsql' stable strict;

