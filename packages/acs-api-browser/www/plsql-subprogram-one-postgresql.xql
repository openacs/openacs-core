<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="source_text">      
      <querytext>

	select definition as text 
	from acs_func_defs 
	where lower(fname)=lower(:name)
    
      </querytext>
</fullquery>

 
</queryset>
