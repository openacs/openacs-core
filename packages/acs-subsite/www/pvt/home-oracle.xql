<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="pvt_home_user_info">      
      <querytext>
      
    select first_names, last_name, email, url,
    nvl(screen_name,'&lt; none set up &gt;') as screen_name
    from cc_users 
    where user_id=:user_id

      </querytext>
</fullquery>

  
<fullquery name="get_portrait_info">      
      <querytext>
      
    select cr.publish_date, nvl(cr.title,'your portrait') as portrait_title
    from cr_revisions cr, cr_items ci, acs_rels a
    where cr.revision_id = ci.live_revision
    and  ci.item_id = a.object_id_two
    and a.object_id_one = :user_id
    and a.rel_type = 'user_portrait_rel'
    
      </querytext>
</fullquery>

 
</queryset>
