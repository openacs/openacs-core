<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="drop_relationship_type">      
      <querytext>
      
	    BEGIN
	      acs_rel_type.drop_type( rel_type  => :rel_type,
                                      cascade_p => 't' );
	    END;
	
      </querytext>
</fullquery>

 
<fullquery name="drop_type_table">      
      <querytext>
      drop table $table_name
      </querytext>
</fullquery>

 
</queryset>
