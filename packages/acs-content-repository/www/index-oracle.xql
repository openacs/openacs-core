<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="content_root">      
      <querytext>
      
      select content_item.get_root_folder from dual

      </querytext>
</fullquery>

 
<fullquery name="template_root">      
      <querytext>

      select content_template.get_root_folder from dual

      </querytext>
</fullquery>

 
</queryset>
