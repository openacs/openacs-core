<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="content_root">      
      <querytext>
      
      select content_item__get_root_folder(null)

      </querytext>
</fullquery>

 
<fullquery name="template_root">      
      <querytext>

      select content_template__get_root_folder()

      </querytext>
</fullquery>

 
</queryset>
