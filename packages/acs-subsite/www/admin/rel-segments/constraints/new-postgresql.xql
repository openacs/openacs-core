<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="add_constraint">      
      <querytext>

	  select rel_constraint__new(
	    null,
	    'rel_constraint',
	    :constraint_name,
	    :rel_segment,
	    :rel_side,
	    :required_rel_segment,
	    null,
	    :creation_user,
	    :creation_ip
	  );
	
      </querytext>
</fullquery>

 
<fullquery name="select_violated_rels">      
      <querytext>
      
	    select viol.rel_id, acs_object__name(viol.party_id) as name
	      from rel_constraints_violated_one viol
	     where viol.constraint_id = :constraint_id
	    UNION ALL
	    select viol.rel_id, acs_object__name(viol.party_id) as name
	      from rel_constraints_violated_two viol
	     where viol.constraint_id = :constraint_id
	
      </querytext>
</fullquery>

 
</queryset>
