<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="source_text">      
      <querytext>

	select text
	from user_source
	where name = upper(:name)
	and type = upper(:type)
	order by line
    
      </querytext>
</fullquery>

 
</queryset>
