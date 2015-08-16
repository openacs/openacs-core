<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs_object_name.object_name_get">      
      <querytext>

        select acs_object__name(:object_id);
    
      </querytext>
</fullquery>

<fullquery name="acs_object::get.select_object">      
      <querytext>

        select o.object_id,
               o.title,
               o.package_id,
               o.object_type,
               o.context_id,
               o.security_inherit_p,
               o.creation_user,
               to_char(o.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date_ansi,
               o.creation_ip,
               to_char(o.last_modified, 'YYYY-MM-DD HH24:MI:SS') as last_modified_ansi,
               o.modifying_user,
               o.modifying_ip,
               acs_object__name(o.object_id) as object_name
        from   acs_objects o
        where  o.object_id = :object_id

      </querytext>
</fullquery>

</queryset>
