<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="delete_constraint">      
      <querytext>

	begin perform rel_constraint__delete(:constraint_id); return null; end;
    
      </querytext>
</fullquery>

 
</queryset>
