<?xml version="1.0"?>
<queryset>

<fullquery name="email_image::get_email.get_email">      
      <querytext>
      
	  select email	
          from parties
          where party_id = :user_id
    
      </querytext>
</fullquery>


<fullquery name="email_image::get_priv_email.get_private_email">      
      <querytext>
     
	  select priv_email
          from users		
          where user_id = :user_id
    
      </querytext>
</fullquery>

<fullquery name="email_image::get_folder_id.check_folder_name">
  <querytext>
	select folder_id from cr_folders
	where label = 'Email_Images'
  </querytext>
</fullquery>

<fullquery name="email_image::get_related_item_id.get_rel_item">
  <querytext>
	select object_id_two from acs_rels
	where rel_type = 'email_image_rel' and object_id_one = :user_id
  </querytext>
</fullquery>

<fullquery name="email_image::update_private_p.update_users">
  <querytext>
        update users
        set priv_email  = :level
        where user_id = :user_id
  </querytext>
</fullquery>



<fullquery name="email_image::new_item.update_cr_items">
  <querytext>
        update cr_items
        set live_revision  = :revision_id
        where item_id = :item_id
  </querytext>
</fullquery>

<fullquery name="email_image::edit_email_image.update_cr_items">
  <querytext>
        update cr_items
        set live_revision  = :revision_id
        where item_id = :item_id
  </querytext>
</fullquery>
  
</queryset>

