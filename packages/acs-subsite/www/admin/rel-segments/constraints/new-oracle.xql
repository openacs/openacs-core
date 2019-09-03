<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

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

</queryset>
