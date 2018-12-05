

DO $$
DECLARE
        v_found boolean;
BEGIN
        --
        -- Was the index already created?
        --
        SELECT exists(
           SELECT relname from pg_class
           WHERE relname ='acs_mail_lite_send_msg_id_map_party_id_idx'
        ) into v_found;
        
        if v_found IS FALSE then
           --
           -- speed up referential integrity
           --
	   CREATE INDEX acs_mail_lite_send_msg_id_map_package_id_idx ON acs_mail_lite_send_msg_id_map(package_id);
	   CREATE INDEX acs_mail_lite_send_msg_id_map_party_id_idx   ON acs_mail_lite_send_msg_id_map(party_id);
	   CREATE INDEX acs_mail_lite_send_msg_id_map_object_id_idx  ON acs_mail_lite_send_msg_id_map(object_id);
        end if;
END$$;

