<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="attribute_properties">      
      <querytext>
      
    select a.pretty_name as attribute_pretty_name, a.datatype, a.attribute_id,
           nvl(a.column_name,a.attribute_name) as attribute_column,
           t.id_column as type_column, t.table_name as type_table, t.object_type,
           a.min_n_values
      from acs_attributes a, acs_object_types t
     where a.attribute_id = :attribute_id
       and a.object_type = t.object_type

      </querytext>
</fullquery>

 
</queryset>
