-- $Id$

drop package acs_sc_msg_type;
drop table acs_sc_msg_type_elements;
drop table acs_sc_msg_types;


delete from acs_objects where object_type = 'acs_sc_msg_type';

begin
   acs_object_type.drop_type('acs_sc_msg_type');
end;
/
show errors



