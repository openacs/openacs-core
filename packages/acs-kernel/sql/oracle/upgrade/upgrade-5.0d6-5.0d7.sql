-- 
-- Upgrade script from 5.0d6 to 5.0d7
--
-- Adds auth_token to users table
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id$
--

alter table users add (auth_token varchar2(100));

