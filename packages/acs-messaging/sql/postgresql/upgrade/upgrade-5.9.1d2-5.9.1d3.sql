--
-- procedure acs_message__edit/10
--
CREATE OR REPLACE FUNCTION acs_message__edit(
   p_message_id integer,
   p_title varchar,             -- default null
   p_description varchar,       -- default null
   p_mime_type varchar,         -- default 'text/plain'
   p_text text,                 -- default null
   p_data integer,              -- default null
   p_creation_date timestamptz, -- default sysdate
   p_creation_user integer,     -- default null
   p_creation_ip varchar,       -- default null
   p_is_live boolean            -- default 't'
) RETURNS integer AS $$
DECLARE
    v_revision_id cr_revisions.revision_id%TYPE;
BEGIN
    -- create a new revision using whichever call is appropriate
    if p_data is not null then
		-- need to take care of blob?
        v_revision_id := content_revision__new (
            p_title,			-- title
            p_description,		-- description
            now(),			-- publish_date
            p_mime_type,		-- mime_type
            null,			-- nls_language
            p_data,			-- data
            p_message_id,		-- item_id
            p_creation_date,		-- creation_date
            p_creation_user,		-- creation_user
            p_creation_ip		-- creation_ip
        );
    else if p_title is not null or p_text is not null then
        v_revision_id := content_revision__new (
            p_title,			-- title
            p_description,		-- description
            now(),			-- publish_date
            p_mime_type,		-- mime_type
            null,			-- nls_language
            p_text,			-- text
            p_message_id,		-- item_id
            null,			-- revision_id
            p_creation_date,		-- creation_date
            p_creation_user,		-- creation_user
            p_creation_ip,		-- creation_ip
	    null,                       -- content_length
	    null			-- package_id
        );      
    end if;
	end if;

    -- test for auto approval of revision   
    if p_is_live then 
        perform content_item__set_live_revision(v_revision_id);
    end if;

    return v_revision_id;
END;
$$ LANGUAGE plpgsql;




DROP FUNCTION IF EXISTS acs_message__new_file(integer,integer,character varying,character varying,text,character varying,integer,timestamp with time zone,integer,character varying,boolean,character varying,integer);
DROP FUNCTION IF EXISTS acs_message__new_file(integer,integer,character varying,character varying,text,character varying,integer,timestamp with time zone,integer,character varying,boolean,character varying);

CREATE OR REPLACE FUNCTION acs_message__new_file(
   p_message_id integer,
   p_file_id integer,                         -- default null
   p_file_name varchar,
   p_title varchar,                           -- default null
   p_description text,                        -- default null
   p_mime_type varchar,                       -- default 'text/plain'
   p_data integer,                            -- default null
   p_creation_date timestamptz,               -- default sysdate
   p_creation_user integer,                   -- default null
   p_creation_ip varchar,                     -- default null
   p_is_live boolean,                         -- default 't'
   p_storage_type cr_items.storage_type%TYPE, -- default 'file'
   p_package_id integer default null
   
) RETURNS integer AS $$
DECLARE
    v_file_id      cr_items.item_id%TYPE;
    v_revision_id  cr_revisions.revision_id%TYPE;
BEGIN
    v_file_id := content_item__new (
        p_file_name,			   -- name           
        p_message_id,			   -- parent_id      
        p_file_id,			   -- item_id        
        null,				   -- locale
        p_creation_date,		   -- creation_date  
        p_creation_user,		   -- creation_user  
        null,				   -- context_id
        p_creation_ip,			   -- creation_ip    
        'content_item',		   	   -- item_subtype
        'content_revision',		   -- content_type
        null,				   -- title
        null,				   -- description
        'text/plain',			   -- mime_type
        null,				   -- nls_language
        null,				   -- text
	null,  				   -- data
	null,  				   -- relation_tag
	false, 				   -- is_live
	p_storage_type,			   -- storage_type
        p_package_id,			   -- package_id
        true                               -- with_child_rels
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
END;
$$ LANGUAGE plpgsql;




DROP FUNCTION IF EXISTS acs_message__new_image(integer,integer,character varying,character varying,text,character varying,integer,integer,integer,timestamp with time zone,integer,character varying,boolean,character varying);
DROP FUNCTION IF EXISTS acs_message__new_image(integer,integer,character varying,character varying,text,character varying,integer,integer,integer,timestamp with time zone,integer,character varying,boolean,character varying,integer);


--
-- procedure acs_message__new_image/15
--
CREATE OR REPLACE FUNCTION acs_message__new_image(
   p_message_id integer,
   p_image_id integer,                         -- default null
   p_file_name varchar,
   p_title varchar,                            -- default null
   p_description text,                         -- default null
   p_mime_type varchar,                        -- default 'text/plain'
   p_data integer,                             -- default null
   p_width integer,                            -- default null
   p_height integer,                           -- default null
   p_creation_date timestamptz,                -- default sysdate
   p_creation_user integer,                    -- default null
   p_creation_ip varchar,                      -- default null
   p_is_live boolean,                          -- default 't'
   p_storage_type cr_items.storage_type%TYPE,  -- default 'file'
   p_package_id integer default null

) RETURNS integer AS $$
DECLARE
    v_image_id     cr_items.item_id%TYPE;
    v_revision_id  cr_revisions.revision_id%TYPE;
BEGIN
    v_image_id := content_item__new (
         p_file_name,				-- name          
         p_message_id,				-- parent_id     
         p_image_id,				-- item_id       
         null,					-- locale
         p_creation_date,			-- creation_date 
         p_creation_user,			-- creation_user 
         null,					-- context_id
         p_creation_ip,				-- creation_ip
	 'content_item',			-- item_subtype
	 'content_revision',			-- content_type
	 null,					-- title
	 null,					-- description
	 'text/plain',			-- mime_type
	 null,					-- nls_language
	 null,					-- text
	 p_storage_type,			-- storage_type
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
END;
$$ LANGUAGE plpgsql;
