
-- Make sure all emails are stored as lowercase
-- Untested
update parties set
  email = lower(email)
 where email <> lower(email);
