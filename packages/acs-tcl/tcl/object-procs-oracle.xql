<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="acs_object_name.object_name_get">      
      <querytext>
      
	begin :1 := acs_object.name(:object_id); end;
    
      </querytext>
</fullquery>

 
</queryset>
