<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_dependents">      
      <querytext>
      
	select r.viol_rel_id as rel_id,
	       acs_object_type.pretty_name(r.viol_rel_type) as rel_type_pretty_name,
	       acs_object.name(r.viol_object_id_one) as object_id_one_name, 
	       acs_object.name(r.viol_object_id_two) as object_id_two_name
	  from rc_violations_by_removing_rel r
	 where r.rel_id = :rel_id
    
      </querytext>
</fullquery>
 
</queryset>
