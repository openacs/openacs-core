
create or replace package sec_session_property
as
    procedure upsert (
       p_session_id in sec_session_properties.session_id%TYPE,
       p_module     in sec_session_properties.module%TYPE,
       p_name       in sec_session_properties.property_name%TYPE,
       p_value      in sec_session_properties.property_value%TYPE,
       p_secure_p   in sec_session_properties.secure_p%TYPE,
       p_last_hit   in sec_session_properties.last_hit%TYPE
    );
end sec_session_property;
/
show errors

create or replace package body sec_session_property
as
    procedure upsert(
       p_session_id in sec_session_properties.session_id%TYPE,
       p_module     in sec_session_properties.module%TYPE,
       p_name       in sec_session_properties.property_name%TYPE,
       p_value      in sec_session_properties.property_value%TYPE,
       p_secure_p   in sec_session_properties.secure_p%TYPE,
       p_last_hit   in sec_session_properties.last_hit%TYPE
    )
    is
    BEGIN
	insert into sec_session_properties
		(session_id, module, property_name, secure_p, last_hit)
	values (p_session_id, p_module, p_name, p_secure_p, p_last_hit);
    exception
        when dup_val_on_index then
	     update sec_session_properties
             set property_value = p_value,
	           secure_p = p_secure_p,
		   last_hit = p_last_hit 
             where
		session_id = p_session_id and
		module = p_module and
		property_name = p_name;
   END upsert;

end sec_session_property;
/
show errors
