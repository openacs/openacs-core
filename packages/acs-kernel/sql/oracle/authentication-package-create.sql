-- PLSQL packages for the authentication datamodel
--
-- @author Peter Marklund
-- @creation-date 2003-08-21

create or replace package authority
as 
    function new(
        authority_id in auth_authorities.authority_id%TYPE default null,
        object_type acs_object_types.object_type%TYPE default 'authority',
        short_name in auth_authorities.short_name%TYPE,
        pretty_name in auth_authorities.pretty_name%TYPE,
        enabled_p in auth_authorities.enabled_p%TYPE default 't',
        sort_order in auth_authorities.sort_order%TYPE,
        auth_impl_id in auth_authorities.auth_impl_id%TYPE default null,
        pwd_impl_id in auth_authorities.pwd_impl_id%TYPE default null,
        forgotten_pwd_url in auth_authorities.forgotten_pwd_url%TYPE default null,
        change_pwd_url in auth_authorities.change_pwd_url%TYPE default null,
        register_impl_id in auth_authorities.register_impl_id%TYPE default null,
        register_url in auth_authorities.register_url%TYPE default null,
        help_contact_text in auth_authorities.help_contact_text%TYPE default null,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    ) return integer;

    function del(
        delete_authority_id in auth_authorities.authority_id%TYPE
    ) return integer;

end authority;
/
show errors

create or replace package body authority
as 
    function new(
        authority_id in auth_authorities.authority_id%TYPE default null,
        object_type acs_object_types.object_type%TYPE default 'authority',
        short_name in auth_authorities.short_name%TYPE,
        pretty_name in auth_authorities.pretty_name%TYPE,
        enabled_p in auth_authorities.enabled_p%TYPE default 't',
        sort_order in auth_authorities.sort_order%TYPE,
        auth_impl_id in auth_authorities.auth_impl_id%TYPE default null,
        pwd_impl_id in auth_authorities.pwd_impl_id%TYPE default null,
        forgotten_pwd_url in auth_authorities.forgotten_pwd_url%TYPE default null,
        change_pwd_url in auth_authorities.change_pwd_url%TYPE default null,
        register_impl_id in auth_authorities.register_impl_id%TYPE default null,
        register_url in auth_authorities.register_url%TYPE default null,
        help_contact_text in auth_authorities.help_contact_text%TYPE default null,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    )
    return integer
    is
        v_authority_id integer; 
        v_sort_order integer;        
    begin
        if sort_order is null then
          select max(sort_order) + 1
                 into v_sort_order
                 from auth_authorities;
        else
           v_sort_order := sort_order;
        end if;


        v_authority_id  := acs_object.new(
            object_id     => new.authority_id,
            object_type   => new.object_type,
            title         => new.short_name,
            creation_date => sysdate(),
            creation_user => new.creation_user,
            creation_ip   => new.creation_ip,
            context_id    => new.context_id
        );

        insert into auth_authorities (authority_id, short_name, pretty_name, enabled_p, 
                                      sort_order, auth_impl_id, pwd_impl_id, 
                                      forgotten_pwd_url, change_pwd_url, register_impl_id,
                                      help_contact_text)
        values (v_authority_id, new.short_name, new.pretty_name, new.enabled_p, 
                                      v_sort_order, new.auth_impl_id, new.pwd_impl_id, 
                                      new.forgotten_pwd_url, new.change_pwd_url, new.register_impl_id, 
                                      new.help_contact_text);

        return v_authority_id;
    end new;

    function del(
        delete_authority_id in auth_authorities.authority_id%TYPE
    )
    return integer
    is
    begin
        acs_object.del(delete_authority_id);

        return 0;
    end del;

end authority;
/
show errors
