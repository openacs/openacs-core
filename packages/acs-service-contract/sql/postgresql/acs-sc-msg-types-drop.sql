drop function acs_sc_msg_type_spec__parse(varchar,varchar);
drop function acs_sc_msg_type_element__new(varchar,varchar,varchar,boolean,integer);
drop table acs_sc_msg_type_element;
drop function acs_sc_msg_type__delete(varchar);
drop function acs_sc_msg_type__delete(integer);
drop function acs_sc_msg_type__get_name(integer);
drop function acs_sc_msg_type__get_id(varchar);
drop function acs_sc_msg_type__new(varchar,varchar);
drop table acs_sc_msg_type;
delete from acs_objects where object_type = 'acs_sc_msg_type';
select acs_object_type__drop_type ('acs_sc_msg_type', 'f');

