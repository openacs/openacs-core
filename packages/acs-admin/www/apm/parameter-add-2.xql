<?xml version="1.0"?>
<queryset>

<fullquery name="param_name_unique_ck">      
      <querytext>
	    select case when count(*) = 0 then 0 else 1 end
	    from apm_parameters
	    where parameter_name = :parameter_name and
              package_key = :package_key
      </querytext>
</fullquery>

 
<fullquery name="apm_parameter_register_doubleclick_p">      
      <querytext>
      
	select 1 from apm_parameters where parameter_id = :parameter_id
    
      </querytext>
</fullquery>

 
</queryset>
