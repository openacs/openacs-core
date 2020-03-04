--
-- Attribute datatype discrepancy fix for object_types in OpenACS:
--
-- Some attribute datatypes where modified in 2006, but an upgrade script
-- adjusting the already existing ones was never done. This one tries to fix this.
--
-- Original datatype change:
-- https://fisheye.openacs.org/changelog/OpenACS?cs=MAIN%3Avictorg%3A20060727200933
-- https://github.com/openacs/openacs-core/commit/7e30fa270483dcbc866ffbf6f5cf4f30447987cb
--

begin;

update acs_attributes set datatype='boolean' where object_type='apm_package_version' and attribute_name='enabled_p';
update acs_attributes set datatype='date' where object_type='apm_package_version' and attribute_name='deactivation_date';
update acs_attributes set datatype='date' where object_type='apm_parameter' and attribute_name='max_n_values';

end;
