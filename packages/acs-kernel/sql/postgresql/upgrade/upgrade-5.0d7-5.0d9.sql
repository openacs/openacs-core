-- Remove obsolete parts of the APM datamodel not used
--
-- @author Peter Marklund

-- *** Remove a column not needed
-- See http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=555
alter table apm_packages drop enabled_p;

-- *** Get rid of file-related data no longer used
drop table apm_package_file_types cascade;
drop table apm_package_files cascade;
-- View was dropped by previous drop
--drop view apm_file_info;
drop function apm_package_version__add_file (integer,integer,varchar,varchar, varchar);
drop function apm_package_version__remove_file (integer,varchar);
drop function apm_package__disable (integer);
drop function apm_package__enable (integer);
