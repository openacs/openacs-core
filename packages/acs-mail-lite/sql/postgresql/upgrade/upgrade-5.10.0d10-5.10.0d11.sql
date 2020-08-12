--
-- Drop duplicate index acs_mail_lite_from_external_aml_email_id_idx.
--
-- An Index for the aml_email_id column of acs_mail_lite_from_external is
-- created automatically by postgres, as this column is the PRIMARY KEY.
--

drop index if exists acs_mail_lite_from_external_aml_email_id_idx;
