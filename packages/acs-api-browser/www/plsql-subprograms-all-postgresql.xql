<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="all_subprograms">      
      <querytext>

	select proname as name, 'FUNCTION' as type, pronargs as nargs 
	from pg_proc 
	where proowner=(select usesysid from pg_user
	                where usename = current_user) 
	order by proname, pronargs
    
      </querytext>
</fullquery>

 
</queryset>
