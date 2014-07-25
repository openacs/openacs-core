-- acs-mail-lite/sql/postgresql/upgrade/upgrade-5.8.1d3-5.8.1d4.sql
--
-- Modify acs_mail_lite_queue
--

-- New columns
alter table acs_mail_lite_queue 
    add column     filesystem_files            text,
    add column     delete_filesystem_files_p   boolean;