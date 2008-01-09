-- acs-mail-lite/sql/postgresql/upgrade/upgrade-5.4.0d2-5.4.0d3.sql
--
-- Modify acs_mail_lite_queue
--

-- New columns
alter table acs_mail_lite_queue 
    add column     creation_date       text,
    add column     locking_server      text,
    add column     cc_addr             text,
    add column     reply_to            text,
    add column     file_ids            text,
    add column     mime_type           text,
    add column     object_id           integer,
    add column     no_callback_p       boolean,
    add column     use_sender_p        boolean;

-- Renamed columns
alter table acs_mail_lite_queue rename column bcc to bcc_addr;
alter table acs_mail_lite_queue rename column extra_headers to extraheaders;

-- Column datatype changes
alter table acs_mail_lite_queue 
    alter column   from_addr   type  text,
    alter column   subject     type  text;
