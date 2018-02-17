--
-- A simple mail queue
--
-- @author <a href="mailto:eric@openforce.net">eric@openforce.net</a>
-- @version $Id$
--

drop table acs_mail_lite_queue;

drop table acs_mail_lite_mail_log; 
drop table acs_mail_lite_bounce; 
drop table acs_mail_lite_bounce_notif;

-- inbound email data model
drop index acs_mail_lite_send_msg_id_map_msg_id_idx;
drop table acs_mail_lite_send_msg_id_map;

drop index acs_mail_lite_ie_part_nv_pairs_aml_email_id_idx;
drop table acs_mail_lite_ie_part_nv_pairs;

drop index acs_mail_lite_ie_section_ref_map_section_id_idx;
drop index acs_mail_lite_ie_section_ref_map_section_ref_idx;
drop table acs_mail_lite_ie_section_ref_map;

drop index acs_mail_lite_ie_parts_aml_email_id_idx;
drop table acs_mail_lite_ie_parts;

drop index acs_mail_lite_ie_headers_aml_email_id_idx;
drop table acs_mail_lite_ie_headers;

drop table acs_mail_lite_ui;

drop table acs_mail_lite_imap_conn;

drop table acs_mail_lite_email_src_ext_id_map;

drop index acs_mail_lite_email_uid_id_map_uid_ext_idx;
drop index acs_mail_lite_email_uid_id_map_src_ext_id_idx;

drop table acs_mail_lite_email_uid_id_map;

drop index acs_mail_lite_from_external_aml_email_id_idx;
drop index acs_mail_lite_from_external_processed_p_idx;
drop index acs_mail_lite_from_external_release_p_idx;



drop table acs_mail_lite_from_external;


drop sequence acs_mail_lite_id_seq;
drop sequence acs_mail_lite_in_id_seq;
