<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="acs_object_name.object_name_get">      
      <querytext>
      
	select acs_object.name(:object_id) from dual
    
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
               acs_object.name(o.object_id) as object_name
        from   acs_objects o
        where  o.object_id = :object_id
    
      </querytext>
</fullquery>
 
</queryset>
