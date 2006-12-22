-- 2006/11/17 cognovis/nfl
--
-- Name: acs_mail_lite_complex_queue; Type: TABLE; Schema: public; Owner: cognovis; Tablespace: 
--
CREATE TABLE acs_mail_lite_complex_queue (
    id 				integer
                                constraint acs_mail_lite_complex_queue_pk 
				PRIMARY KEY,
    creation_date 		text,
    locking_server 		text,
    to_party_ids 		varchar(4000),
    cc_party_ids 		varchar(4000),
    bcc_party_ids 		varchar(4000),
    to_group_ids 		varchar(4000),
    cc_group_ids		varchar(4000),
    bcc_group_ids 		varchar(4000),
    to_addr 			clob,
    cc_addr 			clob,
    bcc_addr			clob,
    from_addr 			varchar(400),
    reply_to 			varchar(400),
    subject 			varchar(4000),
    body 			clob,
    package_id 			integer,
    files 			varchar(4000),
    file_ids 			varchar(4000),
    folder_ids 			varchar(4000),
    mime_type 			varchar(200),
    object_id 			integer,
    single_email_p 		varchar2(1)
				constraint acs_mail_lite_co_qu_single_em_p_ck
				check (valid_email_p in ('t','f')),
    no_callback_p 		varchar2(1)
				constraint acs_mail_lite_co_qu_no_callb_p_ck
				check (valid_email_p in ('t','f')),
    extraheaders 		clob,
    alternative_part_p		varchar2(1)
				constraint acs_mail_lite_co_qu_alt_part_p_ck
				check (valid_email_p in ('t','f')),
    use_sender_p 		varchar2(1)
				constraint acs_mail_lite_co_qu_use_sender_p_ck
				check (valid_email_p in ('t','f'))
);
