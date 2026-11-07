-- Use native conflict handling and avoid rewriting unchanged session properties.

CREATE OR REPLACE FUNCTION sec_session_property__upsert(
       p_session_id bigint,
       p_module varchar,
       p_name varchar,
       p_value varchar,
       p_secure_p boolean,
       p_last_hit integer
) RETURNS void AS
$$
BEGIN
    INSERT INTO sec_session_properties AS p
        (session_id, module, property_name, property_value, secure_p, last_hit)
    VALUES
        (p_session_id, p_module, p_name, p_value, p_secure_p, p_last_hit)
    ON CONFLICT (session_id, module, property_name)
    DO UPDATE SET
        property_value = EXCLUDED.property_value,
        secure_p = EXCLUDED.secure_p,
        last_hit = EXCLUDED.last_hit
    -- Avoid a new tuple and its WAL when all stored values already match.
    WHERE (p.property_value, p.secure_p, p.last_hit)
          IS DISTINCT FROM
          (EXCLUDED.property_value, EXCLUDED.secure_p, EXCLUDED.last_hit);
END;
$$ LANGUAGE plpgsql;
