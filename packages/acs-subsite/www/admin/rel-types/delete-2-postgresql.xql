<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="drop_relationship_type">      
      <querytext>
      
	    BEGIN
	      acs_rel_type__drop_type( rel_type  => :rel_type,
                                      cascade_p => 't' );
	    END;
	
      </querytext>
</fullquery>

 
<fullquery name="drop_type_table">      
      <querytext>
      FIX ME PLSQL
drop table $table_name
      </querytext>
</fullquery>

 
</queryset>
