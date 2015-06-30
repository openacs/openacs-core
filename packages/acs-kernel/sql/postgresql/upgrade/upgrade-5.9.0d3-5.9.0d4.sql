

select define_function_args('sec_session_property__upsert','session_id,module,name,secure_p,last_hit');

CREATE OR REPLACE FUNCTION sec_session_property__upsert(
       p_session_id bigint,
       p_module varchar,
       p_name varchar,
       p_value varchar,
       p_secure_p boolean,
       p_last_hit integer
) RETURNS void as
$$
BEGIN
    LOOP
        -- first try to update the key
    update sec_session_properties
        set   property_value = p_value, secure_p = p_secure_p, last_hit = p_last_hit 
        where session_id = p_session_id and module = p_module and property_name = p_name;
        IF found THEN
            return;
        END IF;
        -- not there, so try to insert the key
        -- if someone else inserts the same key concurrently,
        -- we could get a unique-key failure
        BEGIN
            insert into sec_session_properties
                   (session_id,   module,   property_name, secure_p,   last_hit)
            values (p_session_id, p_module, p_name,        p_secure_p, p_last_hit);
            RETURN;
            EXCEPTION WHEN unique_violation THEN
            -- Do nothing, and loop to try the UPDATE again.
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;




