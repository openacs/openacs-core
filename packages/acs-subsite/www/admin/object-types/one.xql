<?xml version="1.0"?>
<queryset>

<fullquery name="object_type">      
      <querytext>
      
    select supertype,
           abstract_p,
           pretty_name,
           pretty_plural,
           table_name,
           id_column,
           name_method,
           type_extension_table,
           package_name,
           dynamic_p
      from acs_object_types
     where object_type = :object_type

      </querytext>
</fullquery>

 
<fullquery name="attribute">      
      <querytext>
      
    select attribute_name,
           pretty_name,
           pretty_plural,
           datatype,
           default_value,
           min_n_values,
           max_n_values,
           storage,
           table_name as attr_table_name,
           column_name
      from acs_attributes
     where object_type = :object_type

      </querytext>
</fullquery>

 
<fullquery name="table_comment">      
      <querytext>
      select comments from user_tab_comments where table_name = '[string toupper $table_name]'
      </querytext>
</fullquery>

 
<fullquery name="attribute_comment">      
      <querytext>

	select utc.column_name,
	       utc.data_type,
               ucc.comments
	  from user_tab_columns utc left join
               user_col_comments ucc on (utc.table_name= ucc.table_name and utc.column_name = ucc.column_name)
	 where utc.table_name = '[string toupper $table_name]'
    
      </querytext>
</fullquery>

 
</queryset>
