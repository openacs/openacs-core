<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_rel_properties">      
      <querytext>
      
    select s.segment_name, 
           acs_rel_type.role_pretty_name(t.role_one) as role_one_name,
           acs_rel_type.role_pretty_name(t.role_two) as role_two_name
      from rel_segments s, acs_rel_types t
     where s.rel_type = t.rel_type
       and s.segment_id = :rel_segment

      </querytext>
</fullquery>

 
<fullquery name="add_constraint">      
      <querytext>
      
	 BEGIN
	  :1 := rel_constraint.new(constraint_name => :constraint_name,
                                   rel_segment => :rel_segment,
                                   rel_side => :rel_side,
                                   required_rel_segment => :required_rel_segment,
                                   creation_user => :creation_user,
                                   creation_ip => :creation_ip
                                  );
	 END;
	
      </querytext>
</fullquery>

 
<fullquery name="select_violated_rels">      
      <querytext>
      
	    select viol.rel_id, acs_object.name(viol.party_id) as name
	      from rel_constraints_violated_one viol
	     where viol.constraint_id = :constraint_id
	    UNION ALL
	    select viol.rel_id, acs_object.name(viol.party_id) as name
	      from rel_constraints_violated_two viol
	     where viol.constraint_id = :constraint_id
	
      </querytext>
</fullquery>

 
</queryset>
