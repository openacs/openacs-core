<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="folder::delete.delete_folder">
      <querytext>
        select content_folder__delete(:folder_id)
      </querytext>
</fullquery>

</queryset>
