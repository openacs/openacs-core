<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="delete_constraint">      
      <querytext>
      
	begin rel_constraint.del(constraint_id => :constraint_id); end;
    
      </querytext>
</fullquery>

 
</queryset>
