<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="attribute_comment">      
      <querytext>
      
	select utc.column_name,
	       utc.data_type,
               ucc.comments
	  from user_tab_columns utc,
               user_col_comments ucc
	 where utc.table_name = '[string toupper $table_name]'
           and utc.table_name = ucc.table_name(+)
           and utc.column_name = ucc.column_name(+)
    
      </querytext>
</fullquery>

<fullquery name="package_index">      
      <querytext>
      
    select replace (replace (text, ' ', '&nbsp;'), chr(9), '&nbsp;&nbsp;&nbsp;&nbsp;') as text
      from user_source
     where lower(name) = :package_name
       and type = 'PACKAGE BODY'
     order by line

      </querytext>
</fullquery>
 
</queryset>
