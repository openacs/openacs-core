<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_role">      
      <querytext>
      
	    begin acs_rel_type.create_role(role => :role, pretty_name => :pretty_name, pretty_plural => :pretty_plural); end;
	
      </querytext>
</fullquery>

 
</queryset>
