<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="doc::package_info.get_info">      
      <querytext>

        select doc.get_package_header(:package_name) from dual

      </querytext>
</fullquery>

<fullquery name="doc::package_info.get_header">      
      <querytext>

        select doc.get_proc_header(:proc_name, :package_name) from dual
      
      </querytext>
</fullquery>

<fullquery name="doc::package_list.get_packages">      
      <querytext>

       select distinct 
        lower(name) as label,  
        lower(name) as value 
      from 
        user_source
      where 
        type='PACKAGE'
      and
        line=1
      order by label
     
      </querytext>
</fullquery>

<fullquery name="doc::func_list.get_funcs">      
      <querytext>

       select distinct 
        lower(text) as line_header 
      from 
        user_source
      where 
        type='PACKAGE'
      and
        lower(name) = lower(:package_name)
      and (
          lower(text) like '%procedure%'
        or
          lower(text) like '%function%'
      )
      order by line_header
    
      </querytext>
</fullquery> 

<fullquery name="doc::func_multirow.get_functions">      
      <querytext>

      select distinct 
        lower(text) as line_header 
      from 
        user_source
      where 
        type='PACKAGE'
      and
        lower(name) = lower(:package_name)
      and (
          lower(text) like '%procedure%'
        or
          lower(text) like '%function%'
      )
      order by line_header

    
      </querytext>
</fullquery> 

</queryset>
