<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_rel_info">      
      <querytext>
      
    select acs_object_type__pretty_name(r.rel_type) as rel_type_pretty_name,
           acs_object__name(r.object_id_one) as object_id_one_name,
           acs_object__name(r.object_id_two) as object_id_two_name,
           r.object_id_two
      from acs_rels r
     where r.rel_id = :rel_id
      </querytext>
</fullquery>

 
<fullquery name="select_dependants">      
      <querytext>
      
	select r.viol_rel_id as rel_id,
	       acs_object_type__pretty_name(r.viol_rel_type) as rel_type_pretty_name,
	       acs_object__name(r.viol_object_id_one) as object_id_one_name, 
	       acs_object__name(r.viol_object_id_two) as object_id_two_name
	  from rc_violations_by_removing_rel r
	 where r.rel_id = :rel_id
    
      </querytext>
</fullquery>

 
</queryset>
