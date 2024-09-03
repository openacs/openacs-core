--
-- Cleanup leftover util_user_messages
--
delete from sec_session_properties
where module = 'acs-kernel'
  and property_name = 'general_messages';
