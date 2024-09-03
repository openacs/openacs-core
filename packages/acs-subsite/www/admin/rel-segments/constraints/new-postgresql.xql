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

</queryset>
