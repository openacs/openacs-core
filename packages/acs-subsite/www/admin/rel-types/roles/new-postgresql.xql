<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_role">      
      <querytext>
	    select acs_rel_type__create_role(:role, :pretty_name, :pretty_plural)
      </querytext>
</fullquery>

 
</queryset>
