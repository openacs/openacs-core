<?xml version="1.0"?>

<queryset>

  <fullquery name="auth::authority::edit.update_object_title">
      <querytext>
	    update acs_objects
	    set title = :new_short_name
	    where object_id = :authority_id
      </querytext>
  </fullquery>

  <fullquery name="auth::authority::get_authority_options.select_authorities">
      <querytext>
          select pretty_name, authority_id
          from   auth_authorities
          where  enabled_p = 't'
          and    auth_impl_id is not null
          order  by sort_order
      </querytext>
  </fullquery>

  <fullquery name="auth::authority::get_id_not_cached.select_authority_id">
      <querytext>
          select authority_id 
          from   auth_authorities 
          where  short_name = :short_name 
      </querytext>
  </fullquery>

</queryset>
