<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="relation_add.select_rel_violation">      
      <querytext>
      
	    select rel_constraint__violation(:rel_id)

      </querytext>
</fullquery>


<fullquery name="relation_segment_has_dependant.others_depend_p">
      <querytext>

	    select case when exists
	             (select 1 from rc_violations_by_removing_rel r where r.rel_id = :rel_id)
	           then 1 else 0 end


      </querytext>
</fullquery>


<fullquery name="relation_type_is_valid_to_group_p.rel_type_valid_p">
      <querytext>

	    select case when exists
	             (select 1 from rc_valid_rel_types r
                      where r.group_id = :group_id
                        and r.rel_type = :rel_type)
	           then 1 else 0 end


      </querytext>
</fullquery>


</queryset>
