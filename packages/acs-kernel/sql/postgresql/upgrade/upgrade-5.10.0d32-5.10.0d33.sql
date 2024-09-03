
-- Make sure all emails are stored as lowercase
update parties set
  email = lower(email)
 where email <> lower(email);
