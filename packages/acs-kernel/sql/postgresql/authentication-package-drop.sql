-- Drop PLSQL packages for the authentication datamodel
--
-- @author Peter Marklund
-- @creation-date 2003-08-21

drop function authority__del (integer);

drop function authority__new (
    integer, -- authority_id
    varchar, -- object_type
    varchar, -- short_name
    varchar, -- pretty_name
    boolean, -- enabled_p
    integer, -- sort_order
    integer, -- auth_impl_id
    integer, -- pwd_impl_id
    varchar, -- forgotten_pwd_url
    varchar, -- change_pwd_url
    integer, -- register_impl_id
    varchar, -- register_url
    varchar, -- help_contact_text
    integer, -- creation_user
    varchar, -- creation_ip
    integer  -- context_id
);
