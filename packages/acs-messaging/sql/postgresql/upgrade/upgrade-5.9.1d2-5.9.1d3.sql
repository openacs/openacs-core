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

