--
-- Upgrade script from 5.10.0d12 to 5.10.0d13
--
-- @author Hector Romojaro (hector.romojaro@gmail.com)
--
-- @cvs-id $Id$
--

-- Add public_avatar_p preference to user_preferences table
alter table user_preferences add public_avatar_p boolean default 'f';
