<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="doc::package_info.get_info">      
      <querytext>

        select doc__get_package_header(:package_name) from dual

      </querytext>
</fullquery>

<fullquery name="doc::get_proc_header.get_header">      
      <querytext>

        select doc__get_proc_header(:proc_name, :package_name) from dual
      
      </querytext>
</fullquery>

<fullquery name="doc::package_list.get_packages">      
      <querytext>

        select distinct 
          substr(proname,1,position('__' in proname)-1)  as label,
          substr(proname,1,position('__' in proname)-1)  as value        
        from 
          pg_proc 
        where 
          proname like '%\\\_\\\_%' 
        order by 
          label

      </querytext>
</fullquery> 

<fullquery name="doc::func_list.get_funcs">      
      <querytext>

        select 
          'function ' || proname as line_header
        from 
          pg_proc 
        where 
          proname like lower(:package_name) || '\\\_\\\_%' 
        order by 
          line_header
    
      </querytext>
</fullquery> 

<fullquery name="doc::func_multirow.get_functions">      
      <querytext>

        select 
          'function ' || substr(proname,length(:package_name)+3) as line_header
        from 
          pg_proc 
        where 
          proname like lower(:package_name) || '\\\_\\\_%' 
        order by 
          line_header
  
    
      </querytext>
</fullquery> 

</queryset>
