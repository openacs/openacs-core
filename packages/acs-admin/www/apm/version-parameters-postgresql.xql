<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
   <fullquery name="parameter_table">
       <querytext>

            select parameter_name, coalesce(description, 'No Description') as description, datatype, 
                default_value, parameter_id, coalesce(section_name, 'No Section') as section_name
            from apm_parameters
            where package_key = :package_key
            $sql_clauses

       </querytext>
   </fullquery> 
 
</queryset>
