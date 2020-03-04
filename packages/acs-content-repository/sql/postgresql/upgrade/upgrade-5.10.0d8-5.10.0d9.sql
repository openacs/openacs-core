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

update acs_attributes set datatype='integer' where object_type='cr_item_child_rel' and attribute_name='parent_id';
update acs_attributes set datatype='integer' where object_type='cr_item_child_rel' and attribute_name='child_id';
update acs_attributes set datatype='integer' where object_type='cr_item_child_rel' and attribute_name='order_n';
update acs_attributes set datatype='integer' where object_type='cr_item_rel' and attribute_name='item_id';
update acs_attributes set datatype='integer' where object_type='cr_item_rel' and attribute_name='related_object_id';
update acs_attributes set datatype='integer' where object_type='cr_item_rel' and attribute_name='order_n';

end;
