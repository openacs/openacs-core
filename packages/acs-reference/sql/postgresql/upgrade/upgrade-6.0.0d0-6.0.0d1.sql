-- Select the supported creation_ip signature on upgraded databases.
CREATE OR REPLACE FUNCTION acs_reference__new(
   p_table_name varchar,
   p_last_update timestamptz,   -- default sysdate
   p_source varchar,            -- default null
   p_source_url varchar,        -- default null
   p_effective_date timestamptz -- default sysdate

) RETURNS integer AS $$
DECLARE
    v_repository_id acs_reference_repositories.repository_id%TYPE;
BEGIN
    return acs_reference__new(null, p_table_name, 'f', null, null, p_source, p_source_url,
                              p_effective_date, null, null, null, null, null, null::varchar,
                              'acs_reference_repository', null);
END;

$$ LANGUAGE plpgsql;
