<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="package_type_dynamic_p.object_type_dynamic_p">      
      <querytext>
      
	select case when exists (select 1 
                                   from acs_object_types t
                                  where t.dynamic_p = 't'
                                    and t.object_type = :object_type)
	            then 1 else 0 end
	  
    
      </querytext>
</fullquery>

 
<fullquery name="package_create.package_valid_p">      
      <querytext>
      
	    select case when exists (select 1 
                                       from user_objects 
                                      where status = 'INVALID'
                                        and object_name = upper(:package_name)
                                        and object_type = upper(:type))
                        then 0 else 1 end
	      
	
      </querytext>
</fullquery>

 
<fullquery name="package_insert_default_comment.select_comments">      
      <querytext>
      
	    select acs_object.name(:user_id) as author,
	           current_time as creation_date
	      
	
      </querytext>
</fullquery>

 
<fullquery name="package_insert_default_comment.select_comments">      
      <querytext>
      
	    select acs_object.name(:user_id) as author,
	           current_time as creation_date
	      
	
      </querytext>
</fullquery>

 
<fullquery name="package_instantiate_object.create_object">      
      <querytext>
--      FIX ME PLSQL
--    BEGIN
      select ${package_name}__new([plsql_utility::generate_attribute_parameter_call \
	      -prepend ":" \
	      -indent [expr [string length $package_name] + 29] \
	      $pieces]
      );
--    END;

      </querytext>
</fullquery>


</queryset>
