--
-- Drop duplicate index acs_mail_lite_send_msg_id_map_msg_id_idx.
--
-- An Index for the msg_id column of acs_mail_lite_send_msg_id_map is created
-- automatically by postgres, as this column is the PRIMARY KEY.
--

drop index if exists acs_mail_lite_send_msg_id_map_msg_id_idx;
