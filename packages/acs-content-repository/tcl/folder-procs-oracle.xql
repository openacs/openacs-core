<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
 
<fullquery name="folder::delete.delete_folder">
      <querytext>
            begin
            content_folder.delete(:folder_id);
            end;
      </querytext>
</fullquery>

</queryset>
