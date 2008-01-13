-- acs-mail-lite/sql/oracle/upgrade/upgrade-5.4.0d2-5.4.0d3.sql
--
-- Upgrade acs_mail_lite_queue; 
--

-- new columns

alter table acs_mail_lite_queue add  creation_date       varchar(4000);
alter table acs_mail_lite_queue add  locking_server      varchar(4000);
alter table acs_mail_lite_queue add  cc_addr             clob;
alter table acs_mail_lite_queue add  reply_to            varchar(400);
alter table acs_mail_lite_queue add  file_ids            varchar(4000);
alter table acs_mail_lite_queue add  mime_type           varchar(200);
alter table acs_mail_lite_queue add  object_id           integer;
alter table acs_mail_lite_queue add  no_callback_p       char(1)
                                            constraint amlq_no_callback_p_ck
                                            check (no_callback_p in ('t','f'));
alter table acs_mail_lite_queue add  use_sender_p        char(1)
                                            constraint amlq_use_sender_p_ck
                                            check (use_sender_p in ('t','f'));

-- renamed columns
alter table acs_mail_lite_queue rename column bcc to bcc_addr;
alter table acs_mail_lite_queue rename column extra_headers to extraheaders;

-- datatype changes
alter table acs_mail_lite_queue modify    to_addr             varchar(4000);
alter table acs_mail_lite_queue modify    from_addr           varchar(400);
alter table acs_mail_lite_queue modify    subject             varchar(4000);
