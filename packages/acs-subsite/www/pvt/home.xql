<?xml version="1.0"?>
<queryset>

<fullquery name="pvt_home_user_info">      
      <querytext>
      
    select first_names, last_name, email, url, screen_name
    from cc_users 
    where user_id=:user_id

      </querytext>
</fullquery>

 
<fullquery name="biography">      
      <querytext>
      
select attr_value
from acs_attribute_values
where object_id = :user_id
and attribute_id =
   (select attribute_id
    from acs_attributes
    where object_type = 'person'
    and attribute_name = 'bio')
      </querytext>
</fullquery>

 
<fullquery name="get_portrait_info">      
      <querytext>
      
    select cr.publish_date, cr.title as portrait_title, cr.description as portrait_description
    from cr_revisions cr, cr_items ci, acs_rels a
    where cr.revision_id = ci.live_revision
    and  ci.item_id = a.object_id_two
    and a.object_id_one = :user_id
    and a.rel_type = 'user_portrait_rel'
    
      </querytext>
</fullquery>

<fullquery name="email_info">      
      <querytext>
	    select email
	    from cc_users 
	    where user_iad=:user_id
      </querytext>
</fullquery>


 
</queryset>
