drop function acs_sc_msg_type__parse_spec(varchar,varchar);
drop function acs_sc_msg_type__new_element(varchar,varchar,varchar,boolean,integer);
drop table acs_sc_msg_type_elements;
drop function acs_sc_msg_type__delete(varchar);
drop function acs_sc_msg_type__delete(integer);
drop function acs_sc_msg_type__get_name(integer);
drop function acs_sc_msg_type__get_id(varchar);
drop function acs_sc_msg_type__new(varchar,varchar);
drop table acs_sc_msg_types;
delete from acs_objects where object_type = 'acs_sc_msg_type';
select acs_object_type__drop_type ('acs_sc_msg_type', 'f');

