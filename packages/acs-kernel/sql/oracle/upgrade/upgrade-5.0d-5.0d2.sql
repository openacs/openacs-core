-- 
-- Upgrade script from 5.0d to 5.0d2
--
-- @author Simon Carstensen (simon@collaboraid.biz)
--
-- @cvs-id $Id$
--

-- Adds column timezone to table user_preferences

alter table user_preferences add timezone varchar2(100);
