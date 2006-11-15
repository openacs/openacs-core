<?xml version="1.0"?>
<queryset>

   <fullquery name="content::folder::new.insert_cr_folders">      
      <querytext>
	insert into cr_folders (
      	  folder_id, label, description, package_id
	) values (
     	   :folder_id, :label, :description, :package_id
        )
     </querytext>
   </fullquery>

   <fullquery name="content::folder::new.update_object_title">      
      <querytext>
	update acs_objects
          set title = :label
	  where object_id = :folder_id
      </querytext>
   </fullquery>

  <fullquery name="content::folder::new.inherit_folder_type">      
      <querytext>
	insert into cr_folder_type_map
          select
            :folder_id as folder_id, content_type
          from
            cr_folder_type_map
 	  where
	    folder_id = :parent_id
     </querytext>
   </fullquery>

  <fullquery name="content::folder::new.update_parent_folder">      
      <querytext>

	update cr_folders set has_child_folders = 't'
	 where folder_id = :parent_id
 
     </querytext>
   </fullquery>

</queryset>
