<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
   <fullquery name="parameter_table">
       <querytext>

            select parameter_name, nvl(description, 'No Description') description, datatype, 
                default_value, parameter_id, nvl(section_name, 'No Section') section_name
            from apm_parameters
            where package_key = :package_key
            $sql_clauses
       </querytext>
   </fullquery> 
</queryset>
