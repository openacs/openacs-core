-- 
-- Upgrade script from 4.7.2d2 to 5.0d
--
-- @author Don Baccus (dhogaza@pacifier.net)
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id$
--


-- Add support for fast import of data files

insert into apm_package_file_types(file_type_key, pretty_name) values('sql_data', 'SQL Data');
insert into apm_package_file_types(file_type_key, pretty_name) values('ctl_file', 'SQL data loader control');



-- Add locale preference to user_preferences table
alter table user_preferences add locale varchar(30);



-- Add locale preference to apm_packages
alter table apm_packages add default_locale varchar(30);

