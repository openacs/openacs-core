<?xml version="1.0"?>
<queryset>

<fullquery name="acs_lookup_magic_object_no_cache.magic_object_select">
      <querytext>
	select object_id from acs_magic_objects where name = :name
      </querytext>
</fullquery>

<fullquery name="acs_object::package_id_not_cached.get_package_id">
  <querytext>
    select package_id
      from acs_objects
      where object_id = :object_id
   </querytext>
</fullquery>

<fullquery name="acs_object_type.object_type_select">
      <querytext>

        select object_type
        from acs_objects
        where object_id = :object_id

      </querytext>
</fullquery>

<fullquery name="acs_object::set_context_id.update_context_id">
      <querytext>

        update acs_objects
           set context_id = :context_id
         where object_id = :object_id

      </querytext>
</fullquery>

<fullquery name="acs_object::object_p.object_exists">
  <querytext>
    select 1
      from acs_objects
      where object_id = :id
   </querytext>
</fullquery>

</queryset>
