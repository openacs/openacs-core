-- acs-mail-lite/sql/oracle/upgrade/upgrade-5.8.1d3-5.8.1d4.sql
--
-- Upgrade acs_mail_lite_queue; 
--

-- new columns

alter table acs_mail_lite_queue add filesystem_files varchar(4000);
alter table acs_mail_lite_queue add delete_filesystem_files_p boolean;