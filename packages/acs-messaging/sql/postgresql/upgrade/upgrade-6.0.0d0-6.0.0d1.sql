select define_function_args('acs_message__new_extlink','name;null,extlink_id;null,url,label;null,description;null,parent_id,creation_date;sysdate,creation_user;null,creation_ip;null,package_id;null');

CREATE OR REPLACE FUNCTION acs_message__new_extlink(
   p_name varchar,              -- default null
   p_extlink_id integer,        -- default null
   p_url varchar,
   p_label varchar,             -- default null
   p_description text,          -- default null
   p_parent_id integer,
   p_creation_date timestamptz, -- default sysdate
   p_creation_user integer,     -- default null
   p_creation_ip varchar,       -- default null
   p_package_id integer         -- default null

) RETURNS integer AS $$
DECLARE
    v_extlink_id  cr_extlinks.extlink_id%TYPE;
BEGIN
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
END;
$$ LANGUAGE plpgsql;
