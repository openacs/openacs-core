<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="package_index">      
      <querytext>

	select definition as text
	  from acs_func_defs
	 where fname ilike :package_name || '__%'
	 order by fname
      
      </querytext>
</fullquery>

 
</queryset>
